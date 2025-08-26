// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { LibAsset } from "../shared/libraries/LibAsset.sol";

import { InvalidProtocolFeeVault, ZeroAddress, NoTransferToNullAddress, CallerIsNotOwnerOrAdmin } from "./Errors.sol";

/// @title DZapCoreBase
/// @author DZap
/// @notice Base contract containing core state variables, modifiers, and constructor
/// @dev This contract establishes the foundation for the modular DZap architecture
abstract contract DZapCoreBase is Ownable, ERC721Holder, ERC1155Holder, ReentrancyGuard {
    // ============= PUBLIC STORAGE =============
    address public protocolFeeVault;
    address public zapVerifier;
    address public permit2;

    // ============= MAPPINGS =============
    mapping(address user => uint256 nonce) public nonce;
    mapping(address admin => bool isAdmin) public admins;
    mapping(bytes4 selector => bool isBlocked) public blockedSelectors;
    mapping(address adapter => bool isWhitelisted) internal _adaptersAllowlist;

    // ============= IMMUTABLE VARIABLES =============
    address public immutable UNISWAP_PERMIT2;
    bytes32 public immutable EXPECTED_PERMIT2_RUNTIME_HASH;
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    // ============= CONSTANTS =============
    string internal constant _DOMAIN_NAME = "DZapVerifier";
    string internal constant _ZAP_VERSION = "1";

    bytes32 internal constant _GASLESS_WITNESS_TYPEHASH =
        keccak256(
            "DZapGaslessZapWitness(bytes32 txId,address user,address dustReceiver,bytes32 zapDataHash,bytes32 feeDataHash,bytes32 executorFeeDataHash,bytes32 crosschainDataHash,bytes32 sweepDataHash)"
        );

    bytes32 internal constant _SIGNED_GASLESS_DATA_TYPEHASH =
        keccak256(
            "DZapGaslessZapData(bytes32 txId,address user,address dustReceiver,uint256 nonce,uint256 deadline,bytes32 zapDataHash,bytes32 feeDataHash,bytes32 executorFeeDataHash,bytes32 crosschainDataHash,bytes32 sweepDataHash)"
        );

    bytes32 internal constant _SIGNED_ZAP_DATA_TYPEHASH =
        keccak256("DZapSignedZapData(bytes32 txId,address user,uint256 nonce,uint256 deadline,bytes32 zapDataHash,bytes32 feeDataHash)");

    bytes32 private constant _DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)");

    string internal constant _GASLESS_WITNESS_TYPE_STRING =
        "DZapGaslessZapWitness witness)DZapGaslessZapWitness(bytes32 txId,address user,address dustReceiver,bytes32 zapDataHash,bytes32 feeDataHash,bytes32 executorFeeDataHash,bytes32 crosschainDataHash,bytes32 sweepDataHash)TokenPermissions(address token,uint256 amount)";

    // ============= EVENTS =============

    event ProtocolFeeVaultSet(address indexed newVault);
    event ZapVerifierSet(address indexed newVerifier);
    event Permit2Updated();
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event SelectorsBlacklistingUpdated(bytes4[] selectors, bool whitelisted);
    event AdaptersWhitelistingUpdated(address[] adapters, bool whitelisted);
    event Erc1155SpenderWhitelistingUpdated(address[] spenders, bool whitelisted);
    event TokenRecovered(address indexed token, address indexed recipient, uint256 amount);
    event ERC721Recovered(address indexed token, address indexed recipient, uint256 indexed tokenId);
    event ERC1155Recovered(address indexed token, address indexed recipient, uint256[] tokenIds, uint256[] amounts);
    event Zapped(bytes32 indexed transactionId, address indexed user, address indexed integrator, bytes crosschainData);
    event GaslessZapped(bytes32 indexed transactionId, address executor, address indexed user, address indexed integrator, bytes crosschainData);

    // ============= MODIFIERS =============

    /// @notice Restricts access to owner or admin
    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || admins[msg.sender], CallerIsNotOwnerOrAdmin());
        _;
    }

    /// @notice Validates dust receiver address
    modifier validDustReceiver(address _dustReceiver) {
        require(_dustReceiver != address(0), NoTransferToNullAddress());
        _;
    }

    modifier refundExcessNative(address _refundee) {
        uint256 initialBalance = LibAsset.selfNativeBalance() - msg.value;
        _;
        uint256 finalBalance = LibAsset.selfNativeBalance();
        if (finalBalance > initialBalance) LibAsset.transferNativeToken(_refundee, finalBalance - initialBalance);
    }

    // ============= VIEWS =============

    function isAdapterWhitelisted(address adapter) public view returns (bool isWhitelisted) {
        return _adaptersAllowlist[adapter];
    }

    // ============= CONSTRUCTOR =============

    /// @notice Initializes the DZap core base contract
    /// @param _owner Contract owner address
    /// @param _protocolFeeVault Protocol fee recipient address
    /// @param _zapVerifier Address authorized to sign zap verifications
    /// @param _permit2 Permit2 contract address
    /// @param _uniswapPermit2 Uniswap Permit2 contract address
    /// @param _uniswapPermit2BytecodeHash Expected bytecode hash for Uniswap Permit2
    /// @param _salt Domain separator salt
    constructor(
        address _owner,
        address _protocolFeeVault,
        address _zapVerifier,
        address _permit2,
        address _uniswapPermit2,
        bytes32 _uniswapPermit2BytecodeHash,
        bytes32 _salt
    ) Ownable(_owner) {
        require(_zapVerifier != address(0) && _permit2 != address(0), ZeroAddress());
        require(_protocolFeeVault != address(0) && _protocolFeeVault != address(this), InvalidProtocolFeeVault());

        protocolFeeVault = _protocolFeeVault;
        zapVerifier = _zapVerifier;
        permit2 = _permit2;
        UNISWAP_PERMIT2 = _uniswapPermit2;
        EXPECTED_PERMIT2_RUNTIME_HASH = _uniswapPermit2BytecodeHash;

        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(_DOMAIN_TYPEHASH, keccak256(bytes(_DOMAIN_NAME)), keccak256(bytes(_ZAP_VERSION)), block.chainid, address(this), _salt)
        );

        blockedSelectors[IERC20.approve.selector] = true;
        blockedSelectors[IERC20.transfer.selector] = true;
        blockedSelectors[IERC20.transferFrom.selector] = true;

        blockedSelectors[IERC721.approve.selector] = true;
        blockedSelectors[IERC721.transferFrom.selector] = true;
        blockedSelectors[IERC721.setApprovalForAll.selector] = true;
        blockedSelectors[bytes4(keccak256("safeTransferFrom(address,address,uint256)"))] = true;
        blockedSelectors[bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"))] = true;

        blockedSelectors[IERC1155.safeTransferFrom.selector] = true;
        blockedSelectors[IERC1155.safeBatchTransferFrom.selector] = true;
        blockedSelectors[IERC1155.setApprovalForAll.selector] = true;
    }

    // ============= RECEIVE NATIVE TOKENS =============

    /// @notice Allows contract to receive native tokens
    receive() external payable {}
}

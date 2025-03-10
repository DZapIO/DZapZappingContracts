// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

import { LibValidator } from "./../shared/libraries/LibValidator.sol";

import { IDZapWallet } from "../interfaces/IDZapWallet.sol";
import { IDZapWalletFactory } from "../interfaces/IDZapWalletFactory.sol";
import { IDZapExecutor } from "../interfaces/IDZapExecutor.sol";

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { WalletExecutionCallFailed, ExecutorUnauthorizedAccount, SigDeadlineExpired, WalletNotDeployed, QuorumTooLow } from "./../shared/Errors.sol";

/* 
    owner : multisig
*/
contract DZapExecutor is IDZapExecutor, Ownable, Pausable {
    mapping(address executor => bool isWhitelisted) private _executors;
    mapping(address validator => bool isWhitelisted) private _validators;
    uint8 public quorum;

    IDZapWalletFactory public immutable DZAP_FACTORY;

    bytes32 private _DOMAIN_SEPARATOR;
    bytes32 private constant _DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant _VALIDATOR_SIGNED_DATA_TYPEHASH = keccak256("SignedValidatorData(bytes32 txId,address executor,address wallet,uint256 deadline,bytes32 data)");

    // -------------MODIFIERS-------------

    modifier onlyAuthorizedExecutor() {
        require(_executors[msg.sender], ExecutorUnauthorizedAccount(msg.sender));
        _;
    }

    // -------------CONSTRUCTOR-------------

    constructor(address _newOwner, address _dZapFactory, uint8 _quorum, address[] memory _executorsToAdd, address[] memory _validatorsToAdd) Ownable(_newOwner) {
        _DOMAIN_SEPARATOR = keccak256(abi.encode(_DOMAIN_TYPEHASH, keccak256(bytes("DZapExecutor")), keccak256(bytes("1")), block.chainid, address(this)));
        require(_quorum > 0, QuorumTooLow());
        DZAP_FACTORY = IDZapWalletFactory(_dZapFactory);
        quorum = _quorum;
        _setExecutors(_executorsToAdd, true);
        _setValidators(_validatorsToAdd, true);
    }

    // -------------VIEW-------------

    function isExecutorWhitelisted(address _executor) external view returns (bool) {
        return _executors[_executor];
    }

    function isValidatorWhitelisted(address _validator) external view returns (bool) {
        return _validators[_validator];
    }

    // -------------Restricted-------------

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setExecutorWhitelisting(address[] memory _executorsArr, bool _whitelisted) external onlyOwner {
        _setExecutors(_executorsArr, _whitelisted);
        emit ExecutorWhitelistingUpdated(_executorsArr, _whitelisted);
    }

    function setValidatorWhitelisting(address[] memory _validatorArr, bool _whitelisted) external onlyOwner {
        _setValidators(_validatorArr, _whitelisted);
        emit ValidatorWhitelistingUpdated(_validatorArr, _whitelisted);
    }

    /**
     * Sets the new quorum value
     * @param _quorum the new quorum value
     */
    function setQuorum(uint8 _quorum) external onlyOwner {
        require(_quorum != 0, QuorumTooLow());
        quorum = _quorum;

        emit QuorumUpdated(_quorum);
    }

    // -------------EXTERNAL-------------

    /* 
        if wallet is not deployed then deploy the wallet
        verify callData and call execute
        wallet can update executor
     */
    function execute(bytes32 _txId, uint256 _deadline, address _walletAddress, bytes calldata _callData, bytes calldata _validatorSignatures) external payable onlyAuthorizedExecutor whenNotPaused {
        require(DZAP_FACTORY.isWalletDeployed(_walletAddress), WalletNotDeployed());
        _verify(_txId, _walletAddress, _deadline, _callData, _validatorSignatures);
        (bool success, bytes memory res) = _walletAddress.call{ value: msg.value }(_callData);
        require(success, WalletExecutionCallFailed(res));
        emit Executed(_txId, _walletAddress);
    }

    function deployWalletAndExecute(bytes32 _txId, uint256 _deadline, address _userAddress, string memory _label, bytes calldata _callData, bytes calldata _validatorSignatures) external payable onlyAuthorizedExecutor whenNotPaused {
        address walletAddress = DZAP_FACTORY.deploy(_userAddress, _label);
        _verify(_txId, walletAddress, _deadline, _callData, _validatorSignatures);
        (bool success, bytes memory res) = walletAddress.call{ value: msg.value }(_callData);
        require(success, WalletExecutionCallFailed(res));
        emit DeployAndExecuted(_txId, _userAddress, walletAddress);
    }

    // -------------EXTERNAL-------------

    function _verify(bytes32 _txId, address _walletAddress, uint256 _deadline, bytes calldata _data, bytes calldata _validatorSignatures) private view {
        require(_deadline >= block.timestamp, SigDeadlineExpired());
        bytes32 msgHash = keccak256(abi.encode(_VALIDATOR_SIGNED_DATA_TYPEHASH, _txId, msg.sender, _walletAddress, _deadline, keccak256(_data)));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", _DOMAIN_SEPARATOR, msgHash));
        LibValidator.verifyValidatorSigs(_validators, _validatorSignatures, digest, quorum);
    }

    function _setExecutors(address[] memory _executorsArr, bool _whitelisted) private {
        uint256 length = _executorsArr.length;
        for (uint256 i; i < length; ++i) {
            _executors[_executorsArr[i]] = _whitelisted;
        }
    }

    function _setValidators(address[] memory _validatorArr, bool _whitelisted) private {
        uint256 length = _validatorArr.length;
        for (uint256 i; i < length; ++i) {
            _validators[_validatorArr[i]] = _whitelisted;
        }
    }
}

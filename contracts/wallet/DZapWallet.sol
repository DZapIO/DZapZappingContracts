// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import { MinimalWallet } from "../wallet/MinimalWallet.sol";

import { IDZapWalletManager } from "../interfaces/IDZapWalletManager.sol";
import { IDZapWallet } from "../interfaces/IDZapWallet.sol";

import { UnauthorizedCaller, WalletIsPaused, SigDeadlineExpired, NonceAlreadyProcessed, UnauthorizedCall, WalletExecutionFailed } from "../shared/Errors.sol";

/*  
---------------------------------------------------------
---------------------------------------------------------

 /$$$$$$$  /$$$$$$$$  /$$$$$$  /$$$$$$$ 
| $$__  $$|_____ $$  /$$__  $$| $$__  $$
| $$  \ $$     /$$/ | $$  \ $$| $$  \ $$
| $$  | $$    /$$/  | $$$$$$$$| $$$$$$$/
| $$  | $$   /$$/   | $$__  $$| $$____/ 
| $$  | $$  /$$/    | $$  | $$| $$      
| $$$$$$$/ /$$$$$$$$| $$  | $$| $$      
|_______/ |________/|__/  |__/|__/      


Author: DZap <https://dzap.io> (https://x.com/dzap_io)

---------------------------------------------------------
---------------------------------------------------------
*/

contract DZapWallet is Initializable, MinimalWallet, ReentrancyGuardUpgradeable, IDZapWallet {
    // -------------STATE-------------

    IDZapWalletManager public immutable DZAP_WALLET_MANAGER; 
    mapping(uint256 nonce => bool isUsed) public nonces;

    bytes32 private _DOMAIN_SEPARATOR;
    bytes32 private constant _DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 private constant _VALIDATOR_SIGNED_DATA_TYPEHASH = keccak256("SignedValidatorData(bytes32 txId,address sender,uint256 deadline,uint256 nonce,bytes32 data)"); 

    // -------------MODIFIERS-------------

    modifier onlyAuthorizedExecutorOrOwner() {
        require(DZAP_WALLET_MANAGER.isExecutorWhitelisted(msg.sender) || msg.sender == owner, UnauthorizedCaller());
        _;
    }

    modifier whenNotPaused() {
        require(!DZAP_WALLET_MANAGER.walletPaused(), WalletIsPaused());
        _;
    } 

    // -------------INITIALIZER-------------

    constructor(address _dZapWalletManager) {
        DZAP_WALLET_MANAGER = IDZapWalletManager(_dZapWalletManager);
        _disableInitializers();
    }

    function initialize(address _user) public initializer {
        _setOwner(_user);
        __ReentrancyGuard_init();

        _DOMAIN_SEPARATOR = keccak256(abi.encode(_DOMAIN_TYPEHASH, keccak256(bytes("DZapWallet")), block.chainid, address(this)));
    }

    // -------------EXTERNAL-------------

    function execute(bytes32 _txId, uint256 _deadline, uint256 _nonce, bytes calldata _data, bytes calldata _validatorSignatures) external payable onlyAuthorizedExecutorOrOwner whenNotPaused nonReentrant {
        _verify(_txId, _deadline, _nonce, _data, _validatorSignatures);
        nonces[_nonce] = true;

        (address[] memory _callTo, bytes[] memory _callData, uint256[] memory _nativeValue, bool[] memory _isDelegateCall) = abi.decode(_data, (address[], bytes[], uint256[], bool[]));

        uint256 length = _callTo.length;
        for (uint256 i; i < length; ++i) {
            _execute(_callTo[i], _callData[i], _nativeValue[i], _isDelegateCall[i]);
        }

        emit Executed(_txId);
    }

    // -------------INTERNAL-------------

    function _verify(bytes32 _txId, uint256 _deadline, uint256 _nonce, bytes calldata _data, bytes calldata _validatorSignatures) private view {
        require(_deadline >= block.timestamp, SigDeadlineExpired());
        require(!nonces[_nonce], NonceAlreadyProcessed());
        bytes32 msgHash = keccak256(abi.encode(_VALIDATOR_SIGNED_DATA_TYPEHASH, _txId, msg.sender, _deadline, _nonce, keccak256(_data)));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", _DOMAIN_SEPARATOR, msgHash));
        DZAP_WALLET_MANAGER.verify(_validatorSignatures, digest);
    }

    function _execute(address _callTo, bytes memory _callData, uint256 _nativeValue, bool _isDelegateCall) private returns (bool success, bytes memory res) {
        if (_callData.length != 0) {
            if (_isDelegateCall) {
                require(DZAP_WALLET_MANAGER.isCallWhitelisted(_callTo), UnauthorizedCall(_callTo));
                (success, res) = _callTo.delegatecall(_callData);
                require(success, WalletExecutionFailed(_callTo, bytes4(_callData), res));
            } else {
                (success, res) = _callTo.call{ value: _nativeValue }(_callData);
                require(success, WalletExecutionFailed(_callTo, bytes4(_callData), res));
            }
        }
    }
}

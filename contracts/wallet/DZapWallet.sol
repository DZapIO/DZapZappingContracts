// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { MinimalWallet } from "../wallet/MinimalWallet.sol";

import { IDZapRegistry } from "../interfaces/IDZapRegistry.sol";
import { IDZapWallet } from "../interfaces/IDZapWallet.sol";

import { ExecutorUnauthorizedAccount, CallFailed } from "../shared/Errors.sol";

contract DZapWallet is Initializable, MinimalWallet, ReentrancyGuard, IDZapWallet {
    // -------------STATE-------------

    IDZapRegistry public immutable DZAP_REGISTRY;

    // -------------MODIFIERS-------------

    modifier onlyAuthorizedExecutor() {
        require(DZAP_REGISTRY.isExecutorWhitelisted(msg.sender), ExecutorUnauthorizedAccount(msg.sender));
        _;
    }

    // -------------INITIALIZER-------------

    constructor(address _dzapRegistry) {
        DZAP_REGISTRY = IDZapRegistry(_dzapRegistry);
        _disableInitializers();
    }

    function initialize(address _user) public initializer {
        _setOwner(_user);
    }

    // -------------EXTERNAL-------------

    function executeByExecutor(bytes32 _txId, address[] calldata _callTo, bytes[] calldata _callData, uint256[] calldata _nativeValue, bool[] calldata _isDelegateCall) external payable onlyAuthorizedExecutor nonReentrant {
        uint256 length = _callTo.length;
        for (uint256 i; i < length; ++i) {
            _execute(_callTo[i], _callData[i], _nativeValue[i], _isDelegateCall[i]);
        }

        emit Executed(_txId);
    }

    function execute(bytes32 _txId, address[] calldata _callTo, bytes[] calldata _callData, uint256[] calldata _nativeValue, bool[] calldata _isDelegateCall) external payable onlyOwner nonReentrant {
        uint256 length = _callTo.length;
        for (uint256 i; i < length; ++i) {
            _execute(_callTo[i], _callData[i], _nativeValue[i], _isDelegateCall[i]);
        }

        emit Executed(_txId);
    }

    // -------------INTERNAL-------------

    function _execute(address _callTo, bytes memory _callData, uint256 _nativeValue, bool _isDelegateCall) private returns (bool success, bytes memory res) {
        if (_callData.length != 0) {
            if (_isDelegateCall) {
                (success, res) = _callTo.delegatecall(_callData);
                require(success, CallFailed(res));
            } else {
                (success, res) = _callTo.call{ value: _nativeValue }(_callData);
                require(success, CallFailed(res));
            }
        }
    }
}

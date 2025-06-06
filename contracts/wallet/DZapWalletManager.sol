// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { LibValidator } from "./../shared/libraries/LibValidator.sol";

import { IDZapWalletManager } from "../interfaces/IDZapWalletManager.sol";
import { ZeroAddress, QuorumTooLow } from "../shared/Errors.sol";
 
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

contract DZapWalletManager is Ownable, IDZapWalletManager {
    // -------------STATE-------------

    mapping(address executor => bool isWhitelisted) private _executors;
    mapping(address validator => bool isWhitelisted) private _validators;
    mapping(address callTo => bool isWhitelisted) private _allowedCalls;

    address public walletFactory;
    uint8 public quorum;
    uint8 public immutable MIN_QUORUM = 2;

    bool public walletPaused;

    // -------------EVENTS-------------

    event WalletFactoryUpdated(address indexed factory);
    event ExecutorWhitelistingUpdated(address indexed executor, bool isWhitelisted);
    event ValidatorWhitelistingUpdated(address[] validators, bool isWhitelisted);
    event CallsWhitelistingUpdated(address[] callTo, bool isWhitelisted);
    event WalletPaused(bool isPaused);
    event QuorumUpdated(uint8 quorum);

    // -------------CONSTRUCTOR-------------

    constructor(address _owner, address _walletFactory, uint8 _quorum, address[] memory _validatorsToAdd) Ownable(_owner) {
        require(_walletFactory != address(0), ZeroAddress());
        require(_quorum >= MIN_QUORUM, QuorumTooLow());
        walletFactory = _walletFactory;
        quorum = _quorum;
        _setValidators(_validatorsToAdd, true);
    }

    // -------------VIEW-------------

    function isExecutorWhitelisted(address _executor) external view returns (bool) {
        return _executors[_executor];
    }

    function isValidatorWhitelisted(address _validator) external view returns (bool) {
        return _validators[_validator];
    }

    function isCallWhitelisted(address _callTo) external view returns (bool) {
        return _allowedCalls[_callTo];
    }

    function verify(bytes memory _signatures, bytes32 _hash) external view {
        LibValidator.verifyValidatorSigs(_validators, _signatures, _hash, quorum);
    }

    // -------------EXTERNAL-------------

    function updateWalletFactory(address _newWalletFactory) external onlyOwner {
        require(_newWalletFactory != address(0), ZeroAddress());
        
        walletFactory = _newWalletFactory;
        emit WalletFactoryUpdated(_newWalletFactory);
    }
   
    function setWalletPaused(bool _paused) external onlyOwner {
        walletPaused = _paused;
        emit WalletPaused(_paused);
    }

    function setExecutorWhitelisting(address _executor, bool _whitelisted) external onlyOwner {
        require(_executor != address(0), ZeroAddress());
        _executors[_executor] = _whitelisted;
        emit ExecutorWhitelistingUpdated(_executor, _whitelisted);
    }

    function setValidatorWhitelisting(address[] memory _validatorArr, bool _whitelisted) external onlyOwner {
        _setValidators(_validatorArr, _whitelisted);
        emit ValidatorWhitelistingUpdated(_validatorArr, _whitelisted);
    }

    function setCallsWhitelisting(address[] memory _callTos, bool _whitelisted) external onlyOwner {
        uint256 length = _callTos.length;
        for (uint256 i; i < length; ++i) {
            require(_callTos[i] != address(0), ZeroAddress());
            _allowedCalls[_callTos[i]] = _whitelisted;
        }
        emit CallsWhitelistingUpdated(_callTos, _whitelisted);
    }

    function setQuorum(uint8 _quorum) external onlyOwner {
        require(_quorum >= MIN_QUORUM, QuorumTooLow());
        quorum = _quorum;

        emit QuorumUpdated(_quorum);
    }

    // -------------PRIVATE-------------

    function _setValidators(address[] memory _validatorArr, bool _whitelisted) private {
        uint256 length = _validatorArr.length;
        for (uint256 i; i < length; ++i) {
            require(_validatorArr[i] != address(0), ZeroAddress());
            _validators[_validatorArr[i]] = _whitelisted;
        }
    }
}

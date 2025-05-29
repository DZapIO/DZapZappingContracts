// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

import { IDZapWalletFactory } from "../interfaces/IDZapWalletFactory.sol";
import { IDZapExecutor } from "../interfaces/IDZapExecutor.sol";
import { IDZapWallet } from "../interfaces/IDZapWallet.sol";

import { ExecutorUnauthorizedAccount, WalletNotDeployed, ZeroAddress } from "./../shared/Errors.sol";

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

contract DZapExecutor is IDZapExecutor, Ownable, Pausable {
    mapping(address executor => bool isWhitelisted) private _executors;
    IDZapWalletFactory public immutable DZAP_FACTORY;

    // -------------MODIFIERS-------------

    modifier onlyAuthorizedExecutor() {
        require(_executors[msg.sender], ExecutorUnauthorizedAccount(msg.sender));
        _;
    }

    // -------------CONSTRUCTOR-------------

    constructor(address _newOwner, address _dZapFactory, address[] memory _executorsToAdd) Ownable(_newOwner) {
        DZAP_FACTORY = IDZapWalletFactory(_dZapFactory);
        _setExecutors(_executorsToAdd, true);
    }

    // -------------VIEW-------------

    function isExecutorWhitelisted(address _executor) external view returns (bool) {
        return _executors[_executor];
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

    // -------------EXTERNAL-------------

    /* 
        if wallet is not deployed then deploy the wallet
        verify callData and call execute
        wallet can update executor 
     */
    function execute(bytes32 _txId, uint256 _deadline, uint256 _nonce, address _walletAddress, bytes calldata _callData, bytes calldata _validatorSignatures) external payable onlyAuthorizedExecutor whenNotPaused {
        require(DZAP_FACTORY.isWalletDeployed(_walletAddress), WalletNotDeployed());
        IDZapWallet(_walletAddress).execute{ value: msg.value }(_txId, _deadline, _nonce, _callData, _validatorSignatures);
        emit Executed(_txId, _walletAddress);
    }

    function deployWalletAndExecute(bytes32 _txId, uint256 _deadline, uint256 _nonce, address _userAddress, string memory _label, bytes calldata _callData, bytes calldata _validatorSignatures) external payable onlyAuthorizedExecutor whenNotPaused {
        address walletAddress = DZAP_FACTORY.deploy(_userAddress, _label);
        IDZapWallet(walletAddress).execute{ value: msg.value }(_txId, _deadline, _nonce, _callData, _validatorSignatures);
        emit DeployAndExecuted(_txId, _userAddress, walletAddress);
    }

    // -------------EXTERNAL-------------
    function _setExecutors(address[] memory _executorsArr, bool _whitelisted) private {
        uint256 length = _executorsArr.length;
        for (uint256 i; i < length; ++i) {
            require(_executorsArr[i] != address(0), ZeroAddress());
            _executors[_executorsArr[i]] = _whitelisted;
        }
    }
}

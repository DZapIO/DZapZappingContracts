// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

import { ZeroAddress, InvalidWalletImp, AlreadyDeployed, AddressIsWallet, NoLabel } from "../shared/Errors.sol";

import { IDZapWalletFactory } from "../interfaces/IDZapWalletFactory.sol";
import { IDZapWallet } from "../interfaces/IDZapWallet.sol";

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

contract DZapWalletFactory is Ownable, Pausable, IDZapWalletFactory {
    // -------------STATE-------------

    address public walletImp;

    mapping(bytes32 salt => address wallet) public saltToWallet; // user => wallet
    mapping(address wallet => address user) public walletToUser; // wallet => user

    // -------------INITIALIZER-------------

    constructor(address _newOwner, address _walletImp) Ownable(_newOwner) {
        require(_walletImp != address(0), InvalidWalletImp());

        walletImp = _walletImp;
    }

    // -------------VIEW-------------

    function getWalletByLabel(address _user, string memory _label) external view returns (address wallet) {
        return saltToWallet[_createSalt(_user, _label)];
    }

    function isWalletDeployed(address _wallet) external view returns (bool) {
        return walletToUser[_wallet] != address(0);
    }

    function predict(address _user, string memory _label) external view returns (address) {
        if (bytes(_label).length == 0) revert NoLabel();
        bytes32 salt = _createSalt(_user, _label);
        return Clones.predictDeterministicAddress(walletImp, salt);
    }

    // -------------RESTRICTED-------------

    function setWalletImp(address _walletImp) external onlyOwner {
        require(_walletImp != address(0), InvalidWalletImp());

        walletImp = _walletImp;
        emit WalletImpUpdated(_walletImp);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // -------------EXTERNAL-------------

    function deploy(address _user, string memory _label) external whenNotPaused returns (address wallet) {
        if (bytes(_label).length == 0) revert NoLabel();
        bytes32 salt = _createSalt(_user, _label);

        require(saltToWallet[salt] == address(0), AlreadyDeployed());
        require(walletToUser[_user] == address(0), AddressIsWallet());

        return _deploy(_user, salt);
    }

    function getOrDeploy(address _user, string memory _label) external whenNotPaused returns (address wallet) {
        if (bytes(_label).length == 0) revert NoLabel();
        if (walletToUser[_user] != address(0)) return _user;

        bytes32 salt = _createSalt(_user, _label);
        if ((wallet = saltToWallet[salt]) != address(0)) return wallet;

        return _deploy(_user, salt);
    }

    // -------------INTERNAL-------------

    function _deploy(address _user, bytes32 _salt) internal returns (address wallet) {
        require(_user != address(0), ZeroAddress());
        wallet = Clones.cloneDeterministic(walletImp, _salt);

        IDZapWallet(payable(wallet)).initialize(_user);

        saltToWallet[_salt] = wallet;
        walletToUser[wallet] = _user;

        emit WalletDeployed(_user, wallet, _salt);
    }

    function _createSalt(address _user, string memory _label) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_user, _label));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IDZapWalletFactory {
    // -------------EVENTS-------------

    event WalletDeployed(address indexed user, address indexed wallet, bytes32 indexed salt);
    event WalletImpUpdated(address indexed walletImp);

    // -------------EXTERNAL-------------

    function deploy(address _user, string memory _label) external returns (address wallet);

    function getOrDeploy(address _user, string memory _label) external returns (address wallet);

    // -------------VIEW-------------

    function saltToWallet(bytes32 _salt) external returns (address);

    function walletToUser(address _user) external returns (address);

    function getWalletByLabel(address _user, string memory _label) external returns (address);

    function predict(address _user, string memory _label) external view returns (address);

    function isWalletDeployed(address _wallet) external view returns (bool);
}
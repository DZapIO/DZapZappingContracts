// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IDzapWalletFactory {
    function getOrDeploy(address _user) external returns (address wallet);

    function walletRegistry(address _user) external returns (address);

    function userRegistry(address _user) external returns (address);

    function predict(address _user) external view returns (address);

    function isWalletDeployed(address _wallet) external view returns (bool);
}

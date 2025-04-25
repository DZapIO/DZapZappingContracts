// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IDZapWalletManager {
    function walletPaused() external view returns (bool);
    function quorum() external view returns (uint8);
    function verify(bytes memory _signatures, bytes32 _hash) external view;
    function isCallWhitelisted(address _callTo) external view returns (bool);

    function isExecutorWhitelisted(address _executor) external view returns (bool);
    function setExecutorWhitelisting(address _executor, bool _whitelisted) external;
}

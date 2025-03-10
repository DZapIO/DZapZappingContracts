// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IDZapRegistry {
    function isExecutorWhitelisted(address _executor) external view returns (bool);

    function setExecutorWhitelisting(address _executor, bool _whitelisted) external;
}

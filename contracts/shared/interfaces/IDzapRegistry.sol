// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IDzapRegistry {
    function isTargetWhitelisted(address _target) external view returns (bool);

    function isExecutorWhitelisted(address _executor) external view returns (bool);

    function getAdapterForContract(address _contractAddr) external view returns (address);
}

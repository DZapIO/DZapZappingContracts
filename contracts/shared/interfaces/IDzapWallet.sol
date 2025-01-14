// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IDzapWallet {
    function executeDelegateCall(address _target, bytes calldata _callData) external payable;
}

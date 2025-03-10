// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IDZapWallet {
    // -------------EVENTS-------------

    event Executed(bytes32 indexed txId);

    // -------------EXTERNAL-------------

    function initialize(address _user) external;

    function executeByExecutor(
        bytes32 _txId,
        address[] calldata _callTo,
        bytes[] calldata _callData,
        uint256[] calldata _nativeValue,
        bool[] calldata _isDelegateCall
    ) external payable;

    function execute(
        bytes32 _txId,
        address[] calldata _callTo,
        bytes[] calldata _callData,
        uint256[] calldata _nativeValue,
        bool[] calldata _isDelegateCall
    ) external payable;
}

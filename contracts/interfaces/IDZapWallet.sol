// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IDZapWallet {
    // -------------EVENTS-------------

    event Executed(bytes32 indexed txId);

    // -------------EXTERNAL-------------

    function initialize(address _user) external;

    function execute(bytes32 _txId, uint256 _deadline, uint256 _nonce, bytes calldata _data, bytes calldata _validatorSignatures) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IDZapWallet {
    // -------------EVENTS-------------

    event Executed(bytes32 indexed txId);

    // -------------VIEWS-------------

    function getDomainSeparator() external view returns (bytes32);

    // -------------EXTERNAL-------------

    function initialize(address _user, bytes32 _salt) external;

    function execute(bytes32 _txId, uint256 _deadline, uint256 _nonce, bytes calldata _data, bytes calldata _validatorSignatures) external payable;
}

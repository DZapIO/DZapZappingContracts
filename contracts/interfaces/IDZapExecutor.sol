// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IDZapExecutor {
    event ExecutorWhitelistingUpdated(address[] executors, bool isWhitelisted);
    event Executed(bytes32 indexed txId, address indexed walletAddress);
    event DeployAndExecuted(bytes32 indexed txId, address indexed userAddress, address indexed walletAddress);

    function isExecutorWhitelisted(address _executor) external view returns (bool);

    function pause() external;

    function unpause() external;

    function setExecutorWhitelisting(address[] calldata _executorsArr, bool _whitelisted) external;

    function execute(
        bytes32 _txId,
        uint256 _deadline,
        uint256 _nonce,
        address _walletAddress,
        bytes calldata _callData,
        bytes calldata _validatorSignatures
    ) external payable;

    function deployWalletAndExecute(
        bytes32 _txId,
        uint256 _deadline,
        uint256 _nonce,
        address _userAddress,
        string memory _label,
        bytes calldata _callData,
        bytes calldata _validatorSignatures
    ) external payable;
}

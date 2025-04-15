// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IDZapExecutor {
    event QuorumUpdated(uint8 quorum_);
    event ExecutorWhitelistingUpdated(address[] executors, bool isWhitelisted);
    event ValidatorWhitelistingUpdated(address[] validators, bool isWhitelisted);
    event Executed(bytes32 indexed txId, address indexed walletAddress);
    event DeployAndExecuted(bytes32 indexed txId, address indexed userAddress, address indexed walletAddress);

    function isExecutorWhitelisted(address _executor) external view returns (bool);

    function isValidatorWhitelisted(address _validator) external view returns (bool);

    function pause() external;

    function unpause() external;

    function setExecutorWhitelisting(address[] calldata _executorsArr, bool _whitelisted) external;

    function setValidatorWhitelisting(address[] calldata _validatorArr, bool _whitelisted) external;

    function setQuorum(uint8 _quorum) external;

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

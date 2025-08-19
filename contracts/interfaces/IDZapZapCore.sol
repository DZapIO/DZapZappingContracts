// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { InputErc20Tokens, FeeConfig, ZapData, TokenInfo } from "../zap/Types.sol";
import { PermitBatchTransferFrom } from "../interfaces/IPermit2.sol";

interface IDZapZapCore {
    // ============= EXTERNAL FUNCTIONS =============

    /// @notice Executes a zap with individual token permits
    /// @param _transactionId Unique transaction identifier
    /// @param _crosschainData Additional crosschain data
    /// @param _zapVerificationSignature Verifier signature for zap authorization
    /// @param _deadline Signature expiration timestamp
    /// @param _dustReceiver Address to receive leftover tokens
    /// @param _inputTokens Input tokens with permit data
    /// @param _feeConfig Fee distribution configuration
    /// @param _zapData Array of zap execution data
    /// @param _sweepDust Token addresses to sweep as dust
    function zap(
        bytes32 _transactionId,
        bytes calldata _crosschainData,
        bytes calldata _zapVerificationSignature,
        uint256 _deadline,
        address _dustReceiver,
        InputErc20Tokens[] calldata _inputTokens,
        FeeConfig calldata _feeConfig,
        ZapData[] calldata _zapData,
        address[] calldata _sweepDust
    ) external payable;

    /// @notice Executes a zap with batch permit2 transfer
    /// @param _transactionId Unique transaction identifier
    /// @param _crosschainData Additional crosschain data
    /// @param _zapVerificationSignature Verifier signature for zap authorization
    /// @param _batchDepositSignature User signature for batch transfer
    /// @param _deadline Signature expiration timestamp
    /// @param _dustReceiver Address to receive leftover tokens
    /// @param _tokenDepositDetails Batch transfer permit details
    /// @param _feeConfig Fee distribution configuration
    /// @param _zapData Array of zap execution data
    /// @param _sweepDust Token addresses to sweep as dust
    function zap(
        bytes32 _transactionId,
        bytes calldata _crosschainData,
        bytes calldata _zapVerificationSignature,
        bytes calldata _batchDepositSignature,
        uint256 _deadline,
        address _dustReceiver,
        PermitBatchTransferFrom calldata _tokenDepositDetails,
        FeeConfig calldata _feeConfig,
        ZapData[] calldata _zapData,
        address[] calldata _sweepDust
    ) external payable;

    /// @notice Executes a zap with individual token permits
    /// @param _transactionId Unique transaction identifier
    /// @param _crosschainData Additional crosschain data
    /// @param _zapVerificationSignature Verifier signature for zap authorization
    /// @param _userIntentSignature User's intent signature
    /// @param _zapDeadline Zap deadline
    /// @param _userIntentDeadline User intent deadline
    /// @param _user User address
    /// @param _dustReceiver Address to receive leftover tokens
    /// @param _inputTokens Input tokens with permit data
    /// @param _feeConfig Fee distribution configuration
    /// @param _executorFeeInfo Executor fee information
    /// @param _zapData Array of zap execution data
    /// @param _sweepDust Token addresses to sweep as dust
    function executeZap(
        bytes32 _transactionId,
        bytes calldata _crosschainData,
        bytes calldata _zapVerificationSignature,
        bytes calldata _userIntentSignature,
        uint256 _zapDeadline,
        uint256 _userIntentDeadline,
        address _user,
        address _dustReceiver,
        InputErc20Tokens[] calldata _inputTokens,
        FeeConfig calldata _feeConfig,
        TokenInfo[] calldata _executorFeeInfo,
        ZapData[] calldata _zapData,
        address[] calldata _sweepDust
    ) external payable;

    /// @notice Executes a gasless zap on behalf of a user (with batch permit2)
    /// @param _transactionId Unique transaction identifier
    /// @param _crosschainData Additional crosschain data
    /// @param _zapVerificationSignature Verifier signature for zap authorization
    /// @param _userIntentSignature User's signature for gasless execution
    /// @param _zapDeadline Zap verification signature deadline
    /// @param _user User address on whose behalf the zap is executed
    /// @param _dustReceiver Address to receive leftover tokens
    /// @param _tokenDepositDetails Batch transfer permit details
    /// @param _feeConfig Fee distribution configuration
    /// @param _executorFeeInfo Executor fee information
    /// @param _zapData Array of zap execution data
    /// @param _sweepDust Token addresses to sweep as dust
    function executeZap(
        bytes32 _transactionId,
        bytes calldata _crosschainData,
        bytes calldata _zapVerificationSignature,
        bytes calldata _userIntentSignature,
        uint256 _zapDeadline,
        address _user,
        address _dustReceiver,
        PermitBatchTransferFrom calldata _tokenDepositDetails,
        FeeConfig calldata _feeConfig,
        TokenInfo[] calldata _executorFeeInfo,
        ZapData[] calldata _zapData,
        address[] calldata _sweepDust
    ) external payable;
}

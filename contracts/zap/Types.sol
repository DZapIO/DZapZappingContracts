// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Types
/// @notice Contains type definitions

enum PermitType {
    PERMIT, // EIP2612
    PERMIT2_APPROVE,
    PERMIT2_WITNESS_TRANSFER,
    BATCH_PERMIT2_WITNESS_TRANSFER
}

enum TokenType {
    UNDEFINED,
    NATIVE,
    ERC20,
    ERC721,
    ERC1155
}

enum InputTransferType {
    None,
    ApproveForSpender,
    TransferToSpender,
    DirectTransferToSpender,
    ApproveForSpenderViaPermit2
}

enum OutputTransferType {
    ReceiveInContract,
    ReceiveAndTransfer,
    DirectTransferToRecipient
}

struct InputToken {
    TokenType tokenType;
    InputTransferType transferType;
    address tokenAddress;
    uint256 amount;
    uint256 tokenId;
}

struct OutputToken {
    TokenType tokenType;
    OutputTransferType transferType;
    address tokenAddress;
    address recipient;
    uint96 feeAmount;
    uint256 minReturn;
    uint256 tokenId;
}

/// @dev Core zap execution data structure
struct ZapData {
    address callTo; // Address to call for zap execution
    address approveTo; // Address to approve tokens to
    bytes callData; // Encoded function call data
    bool isDelegateCall; // Whether to use delegatecall
    uint256 nativeValue; // Native token value to send
    InputToken[] inputTokens; // Input token specifications
    OutputToken[] outputTokens; // Output token specifications
}

/// @dev ERC20 token input with permit data
struct InputErc20Tokens {
    address token; // Token contract address
    uint256 amount; // Amount to transfer
    bytes permit; // Permit signature data
}

/// @dev Simple token amount pair
struct TokenInfo {
    address token; // Token contract address
    uint256 amount; // Token amount
}

/// @dev Fee distribution data
struct Fees {
    address token; // Fee token address
    uint256 integratorFeeAmount; // Fee amount for integrator
    uint256 protocolFeeAmount; // Fee amount for protocol
}

/// @dev Fee configuration for a transaction
struct FeeConfig {
    address integrator; // Integrator address to receive fees
    Fees[] fees; // Array of fee distributions
}

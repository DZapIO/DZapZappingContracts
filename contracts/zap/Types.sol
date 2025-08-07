// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

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
    address approveTo;
    uint96 fee;
    uint256 amount;
    uint256 tokenId;
}

struct OutputToken {
    TokenType tokenType;
    OutputTransferType transferType;
    address tokenAddress;
    address recipient;
    uint96 fee;
    uint256 minReturn;
    uint256 tokenId;
}

struct ZapData {
    address callTo;
    bytes callData;
    bool isDelegateCall;
    uint256 nativeValue;
    uint128 inputLength;
    uint128 outputLength;
}

struct InputErc20Tokens {
    address token;
    uint256 amount;
    bytes permit;
}

struct ReferralFeeInfo {
    uint96 nativeFeeShare;
    uint96 tokenFeeShare;
}

struct TokenInfo {
    address token;
    uint256 amount;
}

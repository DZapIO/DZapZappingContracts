// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

enum TokenType {
    UNDEFINED,
    NATIVE,
    ERC20,
    ERC721,
    ERC1155
}

enum InputTransferType {
    None, //especially for balancer, where default allowance is > Max, and for delegateCalls
    ApproveForSpender,
    TransferToSpender, // from contract to spender
    DirectTransferToSpender // from user to spender
}

enum OutputTransferType {
    ReceiveInContract, // Token comes into the contract, UseMinAndReturnRemainder
    ReceiveAndTransfer, // Token comes into the contract first, then is transferred to the recipient
    DirectTransferToRecipient // Token is already transferred directly to the recipient
}

struct InputToken {
    TokenType tokenType;
    InputTransferType transferType;
    address tokenAddress;
    address approveTo;
    uint256 amount; // For ERC20 and ERC1155
    uint256 tokenId; // For ERC721 and ERC1155
    uint256 fee; // in percent
}

struct OutputToken {
    TokenType tokenType;
    OutputTransferType transferType;
    address tokenAddress;
    address recipient;
    uint256 minReturn; // For ERC20 and ERC1155
    uint256 tokenId; // For ERC721 and ERC1155
    uint256 fee; // in percent
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
    uint96 tokenFeeShare; // ex 1%
    uint96 nativeFeeShare; // ex 0.5 Matic
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

struct SigData {
    uint256 deadline;
    bytes32 msgHash;
}

enum TokenType {
    ETH,
    ERC20,
    ERC721,
    ERC1155
}

struct TokenTransfer {
    TokenType tokenType;
    address token;
    uint256[] ids; // nftIds
    uint256[] amounts;
    address recipient;
}

struct TokenApproval {
    TokenType tokenType;
    address token;
    address[] operators;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

enum PermitType {
    PERMIT, // EIP2612
    PERMIT2_APPROVE,
    PERMIT2_WITNESS_TRANSFER,
    BATCH_PERMIT2_WITNESS_TRANSFER
}

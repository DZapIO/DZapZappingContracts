// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// ============= ZAP ERRORS =============

error CallerIsNotOwnerOrAdmin();

error ZeroAddress();
error NoTransferToNullAddress();
error DustReceiverIsZeroAddress();
error IntegratorIsZeroAddress();

error UnauthorizedSigner();
error SigDeadlineExpired();

error InvalidRecipient();
error InvalidTokenOwner(uint256);
error InvalidReturnAmount(uint256 returnAmount, uint256 minReturn);
error FeeExceedsReturnAmount(uint256 returnAmount, uint256 feeAmount);

error InvalidProtocolFeeVault();

error UniswapPermit2AlreadySet();
error UniswapPermit2ByteCodeMismatch();

error UnauthorizedCall(address callTo);
error ZapExecutionFailed(address target, bytes4 funSig, bytes reason);
error SelectorNotAllowed(address target, bytes4 selector);
error ProtectedSelector(bytes4 selector);

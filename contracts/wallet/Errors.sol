// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// ============= WALLET ERRORS =============

error ZeroAddress();
error CallerIsNotOwnerOrExecutor();
error UnauthorizedInitializer();
error OwnableUnauthorizedAccount(address);
error InvalidAccount();
error ExecutorUnauthorizedAccount(address);

error InvalidArrayLength();
error WithdrawFailed();

error InvalidWalletImp();
error AlreadyDeployed();
error WalletNotDeployed();
error AddressIsWallet();
error NoLabel();

error WalletIsPaused();

error QuorumTooLow();
error SigDeadlineExpired();
error NonceAlreadyProcessed();

error SelfCallNotAllowed();
error UnauthorizedCall(address callTo);
error WalletExecutionFailed(address target, bytes4 funSig, bytes reason);

// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// ----------COMMON----------

error ZeroAddress();
error NoTransferToNullAddress();
error CallFailed(bytes);
error ZapExecutionFailed(address target, bytes4 funSig, bytes reason);
error InvalidTokenOwner(uint256);
error InvalidReturnAmount(uint256 returnAmount, uint256 minReturn);
error UnauthorizedCaller();

// ----------ASSETS----------

error NativeTransferFailed();
error InvalidAmount();
error NullAddrIsNotAValidSpender();

// ----------Wallet----------

error InvalidWalletImp();
error AlreadyDeployed();
error AddressIsWallet();
error InvalidAccount();
error InvalidNativeValue();
error SigDeadlineExpired();
error NonceAlreadyProcessed();
error ExecutorNotWhitelisted();
error NoLabel();
error WalletNotDeployed();
error WalletExecutionFailed(address target, bytes4 funSig, bytes reason);
error ExecutorUnauthorizedAccount(address);
error OwnableUnauthorizedAccount(address);
error WithdrawFailed();
error InvalidArrayLength();
error QuorumTooLow();
error WalletIsPaused();
error UnauthorizedCall(address callTo);
error SelfCallNotAllowed();

// ----------ZAP----------

error FeeTooHigh();
error InvalidFeeVault();
error InvalidInputLength();
error InvalidOutputLength();
error ReferralAlreadyAdded();
error InvalidOutputType();
error InvalidReferral();
error UnauthorizedSigner();
error SenderCannotBeReferral();
error MaxTokenFeeTooHigh();
error TokenFeeExceedsMax();

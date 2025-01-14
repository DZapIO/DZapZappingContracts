// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// ----------COMMON----------

error ZeroAddress();
error NoTransferToNullAddress();
error UnauthorizedCall(address);
error CallFailed(bytes);
error InvalidTokenOwner(uint256);
error InvalidReturnAmount(uint256 returnAmount, uint256 minReturn);

// ----------Wallet----------
error InvalidWalletImp();

// ----------ASSETS----------

error InvalidNativeTokenAmount();
error InsufficientBalance(uint256 required, uint256 balance);
error NativeTransferFailed();
error NullAddrIsNotAnERC20Token();
error InvalidAmount();
error NullAddrIsNotAValidSpender();
error SlippageTooLow(uint256 desiredAmount, uint256 returnAmount);
error SwapCallFailed(bytes);
error AdapterNotAdded(address);
error InvalidRecipient();
error InvalidTokenForSwap();
error InvalidTokenLength();
error CallerNotWhitelisted(address);
error TargetNotWhitelisted(address);
error InvalidNativeValue();

// ----------FEE COLLECTOR----------

error InvalidNativeFee();
error InvalidTokenFee();

error InvalidFeeAction(bytes4 action);
// error InvalidFeeCategoryOrAction(FeeCategory feeCategory, bytes4 action);
error FeeExceedsMax();
error InvalidFeeCategory();
error InvalidFeeVault();
error InvalidProtocol();

// ----------ZAP----------

error InvalidInputLength();
error InvalidOutputLength();
error FeeTokenMismatched();
error ReferralAlreadyAdded();
error InvalidOutputType();

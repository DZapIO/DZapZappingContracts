// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// ----------COMMON----------

error ZeroAddress();
error NoTransferToNullAddress();
error CallFailed(bytes);
error InvalidTokenOwner(uint256);
error InvalidReturnAmount(uint256 returnAmount, uint256 minReturn);
error UnauthorizedCaller();

// ----------ASSETS----------

error InsufficientBalance(uint256 required, uint256 balance);
error NativeTransferFailed();
error NullAddrIsNotAnERC20Token();
error InvalidAmount();
error NullAddrIsNotAValidSpender();

// ----------ZAP----------

error InvalidFeeVault();
error InvalidInputLength();
error InvalidOutputLength();
error ReferralAlreadyAdded();
error InvalidOutputType();
error InvalidReferral();
error UnauthorizedSigner();

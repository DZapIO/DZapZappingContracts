// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { LibAsset } from "../shared/libraries/LibAsset.sol";
import { DZapVerification } from "./DZapVerification.sol";
import { InputToken, OutputToken, TokenType, InputTransferType, OutputTransferType, TokenInfo, FeeConfig } from "./Types.sol";
import { InvalidTokenOwner, InvalidReturnAmount, InvalidRecipient, FeeExceedsReturnAmount } from "./Errors.sol";

/// @title DZapTokenHandler
/// @author DZap
/// @notice Abstract contract for handling token input and output operations
/// @dev Provides gas-optimized functions for processing various token standards
abstract contract DZapTokenHandler is DZapVerification {
    // ============= INPUT TOKEN PROCESSING =============

    /// @notice Processes all input tokens for a zap operation
    /// @param _inputTokens Array of input token specifications
    /// @param _spender Address to approve/transfer tokens to
    /// @return needsErc1155Revoke Whether any ERC1155 approvals need to be revoked later
    function _processInputTokens(InputToken[] calldata _inputTokens, address _user, address _spender) internal returns (bool needsErc1155Revoke) {
        uint256 length = _inputTokens.length;

        for (uint256 i; i < length; ++i) {
            InputToken memory inputToken = _inputTokens[i];

            if (inputToken.tokenType == TokenType.NATIVE) {
                _handleNativeInput(inputToken, _spender);
            } else if (inputToken.tokenType == TokenType.ERC20) {
                _handleErc20Input(inputToken, _spender);
            } else if (inputToken.tokenType == TokenType.ERC721) {
                _handleErc721Input(inputToken, _user, _spender);
            } else if (inputToken.tokenType == TokenType.ERC1155) {
                needsErc1155Revoke = _handleErc1155Input(inputToken, _user, _spender);
            }
        }
    }

    /// @notice Handles native token input operations
    /// @param _inputToken Input token specification
    /// @param _spender Address to transfer to
    function _handleNativeInput(InputToken memory _inputToken, address _spender) private {
        if (_inputToken.transferType == InputTransferType.TransferToSpender) {
            LibAsset.transferNativeToken(_spender, _inputToken.amount);
        }
    }

    /// @notice Handles ERC20 token input operations
    /// @param _inputToken Input token specification
    /// @param _spender Address to approve/transfer to
    function _handleErc20Input(InputToken memory _inputToken, address _spender) private {
        if (_inputToken.transferType == InputTransferType.ApproveForSpender) {
            LibAsset.maxApproveERC20(_inputToken.tokenAddress, _spender, _inputToken.amount);
        } else if (_inputToken.transferType == InputTransferType.TransferToSpender) {
            LibAsset.transferERC20(_inputToken.tokenAddress, _spender, _inputToken.amount);
        } else if (_inputToken.transferType == InputTransferType.ApproveForSpenderViaPermit2) {
            LibAsset.maxPermit2Approve(permit2, _inputToken.tokenAddress, _spender, _inputToken.amount);
        }
    }

    /// @notice Handles ERC721 token input operations
    /// @param _inputToken Input token specification
    /// @param _spender Address to approve/transfer to
    function _handleErc721Input(InputToken memory _inputToken, address _user, address _spender) private {
        if (_inputToken.transferType == InputTransferType.ApproveForSpender) {
            address currentOwner = LibAsset.getOwnerOfERC721(_inputToken.tokenAddress, _inputToken.tokenId);
            if (currentOwner != address(this)) {
                LibAsset.transferERC721(_inputToken.tokenAddress, _user, address(this), _inputToken.tokenId);
            }
            LibAsset.approveERC721(_inputToken.tokenAddress, _spender, _inputToken.tokenId);
        } else if (_inputToken.transferType == InputTransferType.TransferToSpender) {
            LibAsset.transferERC721(_inputToken.tokenAddress, _spender, _inputToken.tokenId);
        } else if (_inputToken.transferType == InputTransferType.DirectTransferToSpender) {
            LibAsset.transferERC721(_inputToken.tokenAddress, _user, _spender, _inputToken.tokenId);
        }
    }

    /// @notice Handles ERC1155 token input operations
    /// @param _inputToken Input token specification
    /// @param _spender Address to approve/transfer to
    /// @return needsRevoke Whether approval should be revoked after execution
    function _handleErc1155Input(InputToken memory _inputToken, address _user, address _spender) private returns (bool needsRevoke) {
        if (_inputToken.transferType == InputTransferType.DirectTransferToSpender) {
            LibAsset.transferERC1155(_inputToken.tokenAddress, _user, _spender, _inputToken.tokenId, _inputToken.amount);
            return false;
        }

        uint256 currentBalance = LibAsset.getBalanceOfERC1155(_inputToken.tokenAddress, address(this), _inputToken.tokenId);

        if (currentBalance < _inputToken.amount) {
            uint256 needed = _inputToken.amount - currentBalance;
            LibAsset.transferERC1155(_inputToken.tokenAddress, _user, address(this), _inputToken.tokenId, needed);
        }

        if (_inputToken.transferType == InputTransferType.ApproveForSpender) {
            needsRevoke = true;
            LibAsset.approveERC1155(_inputToken.tokenAddress, _spender);
        } else if (_inputToken.transferType == InputTransferType.TransferToSpender) {
            LibAsset.transferERC1155(_inputToken.tokenAddress, address(this), _spender, _inputToken.tokenId, _inputToken.amount);
        }
    }

    /// @notice Revokes ERC1155 approvals after zap execution
    /// @param _inputTokens Array of input tokens
    /// @param _spender Address to revoke approvals from
    function _revokeErc1155Approvals(InputToken[] calldata _inputTokens, address _spender) internal {
        uint256 length = _inputTokens.length;
        for (uint256 i; i < length; ++i) {
            if (_inputTokens[i].tokenType == TokenType.ERC1155 && _inputTokens[i].transferType == InputTransferType.ApproveForSpender) {
                LibAsset.revokeERC1155(_inputTokens[i].tokenAddress, _spender);
            }
        }
    }

    // ============= OUTPUT TOKEN PROCESSING =============

    /// @notice Gets initial balances for output tokens before zap execution
    /// @param _outputTokens Array of output token specifications
    /// @param _nativeValueUsed Native value being used in the execution
    /// @return initialBalances Array of initial balances
    function _getOutputTokensInitialBalances(
        OutputToken[] calldata _outputTokens,
        uint256 _nativeValueUsed
    ) internal view returns (uint256[] memory initialBalances) {
        uint256 length = _outputTokens.length;
        initialBalances = new uint256[](length);

        for (uint256 i; i < length; ++i) {
            OutputToken memory outputToken = _outputTokens[i];

            if (outputToken.transferType == OutputTransferType.ReceiveInContract) {
                require(outputToken.recipient == address(this), InvalidRecipient());
            }

            address recipient = _getRecipient(outputToken);

            if (outputToken.tokenType == TokenType.ERC20) {
                initialBalances[i] = LibAsset.getErc20Balance(outputToken.tokenAddress, recipient);
            } else if (outputToken.tokenType == TokenType.NATIVE) {
                uint256 balance = recipient == address(this) ? LibAsset.selfNativeBalance() - _nativeValueUsed : LibAsset.getNativeBalance(recipient);
                initialBalances[i] = balance;
            } else if (outputToken.tokenType == TokenType.ERC1155) {
                initialBalances[i] = LibAsset.getBalanceOfERC1155(outputToken.tokenAddress, recipient, outputToken.tokenId);
            }
        }
    }

    /// @notice Processes all output tokens after zap execution
    /// @param _outputTokens Array of output token specifications
    /// @param _initialBalances Array of initial balances before execution
    function _processOutputTokens(OutputToken[] calldata _outputTokens, uint256[] memory _initialBalances) internal {
        uint256 length = _outputTokens.length;

        for (uint256 i; i < length; ++i) {
            TokenType tokenType = _outputTokens[i].tokenType;

            if (tokenType == TokenType.ERC20) {
                _handleERC20Output(_outputTokens[i], _initialBalances[i]);
            } else if (tokenType == TokenType.NATIVE) {
                _handleNativeOutput(_outputTokens[i], _initialBalances[i]);
            } else if (tokenType == TokenType.ERC721) {
                _handleERC721Output(_outputTokens[i]);
            } else if (tokenType == TokenType.ERC1155) {
                _handleERC1155Output(_outputTokens[i], _initialBalances[i]);
            }
        }
    }

    /// @notice Handles ERC20 output token validation and transfer
    /// @param _outputToken Output token specification
    /// @param _initialBalance Initial balance before execution
    function _handleERC20Output(OutputToken calldata _outputToken, uint256 _initialBalance) private {
        address recipient = _getRecipient(_outputToken);
        uint256 currentBalance = LibAsset.getBalance(_outputToken.tokenAddress, recipient);
        uint256 returnAmount = currentBalance - _initialBalance;

        if (returnAmount < _outputToken.minReturn) {
            revert InvalidReturnAmount(returnAmount, _outputToken.minReturn);
        }

        if (_outputToken.transferType == OutputTransferType.ReceiveAndTransfer) {
            require(_outputToken.feeAmount <= returnAmount, FeeExceedsReturnAmount(returnAmount, _outputToken.feeAmount));
            uint256 transferAmount = _outputToken.feeAmount > 0 ? returnAmount - _outputToken.feeAmount : returnAmount;
            LibAsset.transferERC20(_outputToken.tokenAddress, _outputToken.recipient, transferAmount);
        }
    }

    /// @notice Handles native token output validation and transfer
    /// @param _outputToken Output token specification
    /// @param _initialBalance Initial balance before execution
    function _handleNativeOutput(OutputToken calldata _outputToken, uint256 _initialBalance) private {
        address recipient = _getRecipient(_outputToken);
        uint256 currentBalance = LibAsset.getBalance(_outputToken.tokenAddress, recipient);
        uint256 returnAmount = currentBalance - _initialBalance;

        if (returnAmount < _outputToken.minReturn) {
            revert InvalidReturnAmount(returnAmount, _outputToken.minReturn);
        }

        if (_outputToken.transferType == OutputTransferType.ReceiveAndTransfer) {
            uint256 transferAmount = returnAmount - _outputToken.feeAmount;
            LibAsset.transferNativeToken(_outputToken.recipient, transferAmount);
        }
    }

    /// @notice Handles ERC721 output validation and transfer
    /// @param _outputToken Output token specification
    function _handleERC721Output(OutputToken calldata _outputToken) private {
        address recipient = _getRecipient(_outputToken);
        address tokenOwner = LibAsset.getOwnerOfERC721(_outputToken.tokenAddress, _outputToken.tokenId);

        if (recipient != tokenOwner) {
            revert InvalidTokenOwner(_outputToken.tokenId);
        }

        if (_outputToken.transferType == OutputTransferType.ReceiveAndTransfer) {
            LibAsset.transferERC721(_outputToken.tokenAddress, _outputToken.recipient, _outputToken.tokenId);
        }
    }

    /// @notice Handles ERC1155 output validation and transfer
    /// @param _outputToken Output token specification
    /// @param _initialBalance Initial balance before execution
    function _handleERC1155Output(OutputToken calldata _outputToken, uint256 _initialBalance) private {
        address recipient = _getRecipient(_outputToken);
        uint256 currentBalance = LibAsset.getBalanceOfERC1155(_outputToken.tokenAddress, recipient, _outputToken.tokenId);
        uint256 returnAmount = currentBalance - _initialBalance;

        if (returnAmount < _outputToken.minReturn) {
            revert InvalidReturnAmount(returnAmount, _outputToken.minReturn);
        }

        if (_outputToken.transferType == OutputTransferType.ReceiveAndTransfer) {
            LibAsset.transferERC1155(_outputToken.tokenAddress, address(this), _outputToken.recipient, _outputToken.tokenId, returnAmount);
        }
    }

    /// @notice Determines the actual recipient address for output tokens
    /// @param _outputToken Output token specification
    /// @return recipient The actual recipient address
    function _getRecipient(OutputToken memory _outputToken) private view returns (address recipient) {
        recipient = _outputToken.transferType == OutputTransferType.ReceiveAndTransfer ? address(this) : _outputToken.recipient;
    }

    // ============= FEE AND SWEEP FUNCTIONS =============

    /// @notice Processes fee payments to integrator and protocol
    /// @param _feeConfig Fee configuration
    function _processFee(FeeConfig calldata _feeConfig) internal {
        uint256 length = _feeConfig.fees.length;

        for (uint256 i; i < length; ++i) {
            LibAsset.transferToken(_feeConfig.fees[i].token, _feeConfig.integrator, _feeConfig.fees[i].integratorFeeAmount);
            LibAsset.transferToken(_feeConfig.fees[i].token, protocolFeeVault, _feeConfig.fees[i].protocolFeeAmount);
        }
    }

    /// @notice Transfers executor fees to the transaction executor
    /// @param _executorFeeInfo Array of executor fee specifications
    function _transferExecutorFees(TokenInfo[] calldata _executorFeeInfo) internal {
        uint256 length = _executorFeeInfo.length;

        for (uint256 i; i < length; ++i) {
            LibAsset.transferERC20WithoutChecks(_executorFeeInfo[i].token, msg.sender, _executorFeeInfo[i].amount);
        }
    }

    /// @notice Sweeps remaining tokens to dust receiver
    /// @param _sweepTokens Array of token addresses to sweep
    /// @param _dustReceiver Address to receive swept tokens
    function _handleSweepTokens(address[] calldata _sweepTokens, address _dustReceiver) internal {
        uint256 length = _sweepTokens.length;

        for (uint256 i; i < length; ++i) {
            address tokenAddress = _sweepTokens[i];
            uint256 balance = LibAsset.getBalance(tokenAddress, address(this));

            if (balance > 0) {
                LibAsset.transferERC20WithoutChecks(tokenAddress, _dustReceiver, balance);
            }
        }
    }
}

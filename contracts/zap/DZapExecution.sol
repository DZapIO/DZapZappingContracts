// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { DZapTokenHandler } from "./DZapTokenHandler.sol";
import { ZapData } from "./Types.sol";
import { UnauthorizedCall, ZapExecutionFailed, SelectorNotAllowed } from "./Errors.sol";

/// @title DZapExecution
/// @author DZap
/// @notice Abstract contract for handling zap execution logic
/// @dev Provides gas-optimized execution of external calls and zap operations
abstract contract DZapExecution is DZapTokenHandler {
    // ============= CORE EXECUTION FUNCTIONS =============

    /// @notice Executes a single external call (regular call or delegatecall)
    /// @param _zapData Zap execution data containing call information
    function _execute(ZapData memory _zapData) internal {
        if (_zapData.callData.length == 0) return;

        bool success;
        bytes memory result;

        if (_zapData.isDelegateCall) {
            require(_zapData.callTo != address(this), UnauthorizedCall(_zapData.callTo));

            // solhint-disable-next-line
            (success, result) = _zapData.callTo.delegatecall(_zapData.callData);
        } else {
            bytes4 selector = bytes4(_zapData.callData);
            require(!blockedSelectors[selector], SelectorNotAllowed(_zapData.callTo, selector));

            (success, result) = _zapData.callTo.call{ value: _zapData.nativeValue }(_zapData.callData);
        }

        require(success, ZapExecutionFailed(_zapData.callTo, bytes4(_zapData.callData), result));
    }

    /// @notice Executes a complete zap operation with multiple steps
    /// @param _zapData Array of zap execution steps
    function _handleZap(ZapData[] calldata _zapData, address _user) internal {
        uint256 length = _zapData.length;

        for (uint256 i; i < length; ++i) {
            bool needsErc1155Revoke = _processInputTokens(_zapData[i].inputTokens, _user, _zapData[i].approveTo);

            uint256[] memory initialOutputBalances = _getOutputTokensInitialBalances(_zapData[i].outputTokens, _zapData[i].nativeValue);

            _execute(_zapData[i]);

            _processOutputTokens(_zapData[i].outputTokens, initialOutputBalances);

            if (needsErc1155Revoke) {
                _revokeErc1155Approvals(_zapData[i].inputTokens, _zapData[i].approveTo);
            }
        }
    }
}

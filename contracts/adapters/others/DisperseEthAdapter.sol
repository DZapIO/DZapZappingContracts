// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title DisperseEthAdapter
/// @author DZap
contract DisperseEthAdapter {
    // ============= ERRORS =============

    error NativeTransferFailed();

    // ============= FUNCTIONS =============

    /// @notice Transfers native tokens to multiple recipients
    /// @param _recipients Array of recipient addresses
    /// @param _amount Array of amounts to transfer
    function transferEth(address[] calldata _recipients, uint256[] calldata _amount) external payable {
        uint256 length = _recipients.length;
        for (uint256 i; i < length; ++i) {
            (bool success, ) = _recipients[i].call{ value: _amount[i] }("");
            require(success, NativeTransferFailed());
        }
    }

    /// @notice Transfers native tokens to a single recipient
    /// @param _recipient Recipient address
    /// @param _amount Amount to transfer
    function transferEth(address _recipient, uint256 _amount) external payable {
        (bool success, ) = _recipient.call{ value: _amount }("");
        require(success, NativeTransferFailed());
    }
}

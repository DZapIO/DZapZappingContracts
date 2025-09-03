// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IFluidVaultT4 {
    /// @notice Performs operations on a vault position with perfect collateral shares
    /// @dev This function allows users to modify their vault position by adjusting collateral and debt
    /// @param nftId_ The ID of the NFT representing the vault position
    /// @param perfectColShares_ The change in collateral shares (positive for deposit, negative for withdrawal)
    /// @param colToken0MinMax_ Min or max collateral amount of token0 to withdraw or deposit (positive for deposit, negative for withdrawal)
    /// @param colToken1MinMax_ Min or max collateral amount of token1 to withdraw or deposit (positive for deposit, negative for withdrawal)
    /// @param perfectDebtShares_ The change in debt shares (positive for borrowing, negative for repayment)
    /// @param debtToken0MinMax_ Min or max debt amount for token0 to borrow or payback (positive for borrowing, negative for repayment)
    /// @param debtToken1MinMax_ Min or max debt amount for token1 to borrow or payback (positive for borrowing, negative for repayment)
    /// @param to_ The address to receive funds (if address(0), defaults to msg.sender)
    /// @return nftId_ The ID of the NFT representing the updated vault position
    /// @return r_ int256 array of return values:
    ///              0 - final col shares amount (can only change on max withdrawal)
    ///              1 - token0 deposit or withdraw amount
    ///              2 - token1 deposit or withdraw amount
    ///              3 - final debt shares amount (can only change on max payback)
    ///              4 - token0 borrow or payback amount
    ///              5 - token1 borrow or payback amount
    function operatePerfect(
        uint256 nftId_,
        int256 perfectColShares_,
        int256 colToken0MinMax_,
        int256 colToken1MinMax_,
        int256 perfectDebtShares_,
        int256 debtToken0MinMax_,
        int256 debtToken1MinMax_,
        address to_
    )
        external
        payable
        returns (
            uint256, // nftId_
            int256[] memory r_
        );
}

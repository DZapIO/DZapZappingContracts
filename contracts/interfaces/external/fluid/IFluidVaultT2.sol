// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IFluidVaultT2 {
    /// @notice Performs operations on a vault position with perfect collateral shares
    /// @dev This function allows users to modify their vault position by adjusting collateral and debt
    /// @param nftId_ The ID of the NFT representing the vault position
    /// @param perfectColShares_ The change in collateral shares (positive for deposit, negative for withdrawal)
    /// @param colToken0MinMax_ min or max collateral amount of token0 to withdraw or deposit (positive for deposit, negative for withdrawal)
    /// @param colToken1MinMax_ min or max collateral amount of token1 to withdraw or deposit (positive for deposit, negative for withdrawal)
    /// @param newDebt_ The change in debt amount (positive for borrowing, negative for repayment)
    /// @param to_ The address to receive withdrawn collateral or borrowed tokens (if address(0), defaults to msg.sender)
    /// @return nftId_ The ID of the NFT representing the updated vault position
    /// @return r_ int256 array of return values:
    ///              0 - final col shares amount (can only change on max withdrawal)
    ///              1 - token0 deposit or withdraw amount
    ///              2 - token1 deposit or withdraw amount
    ///              3 - newDebt_ will only change if user sent type(int).min
    function operatePerfect(
        uint256 nftId_,
        int256 perfectColShares_,
        int256 colToken0MinMax_,
        int256 colToken1MinMax_,
        int256 newDebt_,
        address to_
    )
        external
        payable
        returns (
            uint256, // nftId_
            int256[] memory r_
        );
}

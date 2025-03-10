// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IAerodromeClGauge {
    /// @notice Used to deposit a CL position into the gauge
    /// @notice Allows the user to receive emissions instead of fees
    /// @param tokenId The tokenId of the position
    function deposit(uint256 tokenId) external;

    /// @notice Used to deposit a CL position into the gauge
    /// @notice Used to withdraw a CL position from the gauge
    /// @notice Allows the user to receive fees instead of emissions
    /// @notice Outstanding emissions will be collected on withdrawal
    /// @param tokenId The tokenId of the position
    function withdraw(uint256 tokenId) external;

    /// @notice Retrieve rewards for a tokenId
    /// @dev Throws if not called by the position owner
    /// @param tokenId The tokenId of the position
    function getReward(uint256 tokenId) external;

    function nft() external view returns (address);

    function earned(address account, uint256 tokenId) external view returns (uint256);
}

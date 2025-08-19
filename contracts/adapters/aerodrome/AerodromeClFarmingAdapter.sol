// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Enumerable } from "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IAerodromeClGauge } from "../../interfaces/external/aerodrome/IAerodromeClGauge.sol";

/// @title AerodromeClFarmingAdapter
/// @author DZap
contract AerodromeClFarmingAdapter {
    using SafeERC20 for IERC20;

    // ============= FUNCTIONS =============

    /// @notice Deposits an NFT into the gauge
    function deposit(address _gauge, address _token, uint256 _tokenId, uint256 _tokenBalance) external {
        if (_tokenId == 0) {
            _tokenId = IERC721Enumerable(_token).tokenOfOwnerByIndex(address(this), _tokenBalance);
        }
        IERC721(_token).approve(_gauge, _tokenId);
        IAerodromeClGauge(_gauge).deposit(_tokenId);
    }

    /// @notice Withdraws an NFT from the gauge
    function withdraw(address _gauge, uint256 _tokenId) external {
        IAerodromeClGauge(_gauge).withdraw(_tokenId);
    }

    /// @notice Withdraws an NFT from the gauge and transfers rewards
    function withdrawAndTransfer(
        address _gauge,
        address _nftToken,
        address _rewardToken,
        address _nftRecipient,
        address _rewardRecipient,
        uint256 _tokenId
    ) external {
        uint256 initalBalance = IERC20(_rewardToken).balanceOf(address(this));
        IAerodromeClGauge(_gauge).withdraw(_tokenId);
        uint256 rewards = IERC20(_rewardToken).balanceOf(address(this)) - initalBalance;

        if (_nftRecipient != address(this)) {
            IERC721(_nftToken).safeTransferFrom(address(this), _nftRecipient, _tokenId);
        }

        if (rewards > 0 && _rewardRecipient != address(this)) {
            IERC20(_rewardToken).safeTransfer(_rewardRecipient, rewards);
        }
    }

    /// @notice Claims rewards from the gauge
    function claim(address _gauge, uint256 _tokenId) external {
        IAerodromeClGauge(_gauge).getReward(_tokenId);
    }

    /// @notice Claims rewards from the gauge and transfers rewards
    function claimAndTransfer(address _gauge, address _rewardToken, address _recipient, uint256 _tokenId) external {
        uint256 initalBalance = IERC20(_rewardToken).balanceOf(address(this));
        IAerodromeClGauge(_gauge).getReward(_tokenId);
        uint256 rewards = IERC20(_rewardToken).balanceOf(address(this)) - initalBalance;

        if (_recipient != address(this)) {
            IERC20(_rewardToken).safeTransfer(_recipient, rewards);
        }
    }
}

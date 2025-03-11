// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Enumerable } from "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IFluidVaultT1 } from "../../interfaces/external/fluid/IFluidVaultT1.sol";

import "hardhat/console.sol";

contract FluidVaultAdapter {
    using SafeERC20 for IERC20;

    function depositNewPosition(
        address _nft, 
        address _vault, 
        address _recipient,
        int256 _newCol, 
        int256 _newDebt
    ) external {
        uint256 tokenBalance = IERC721(_nft).balanceOf(address(this));
        console.log("deposit", tokenBalance);
        IFluidVaultT1(_vault).operate(0, _newCol, _newDebt, _recipient);

        uint256 tokenId = IERC721Enumerable(_nft).tokenOfOwnerByIndex(address(this), tokenBalance);
        console.log("tokenId", tokenId);
        IERC721(_nft).safeTransferFrom(address(this), _recipient, tokenId);
    }
}

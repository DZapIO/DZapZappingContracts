// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IFluidVault } from "../../interfaces/external/fluid/IFluidVaultT1.sol";

contract FluidVaultAdapter {
    function depositNewPositionT1(
        address _nft, 
        address _vault, 
        address _recipient,
        int256 _newCol, 
        int256 _newDebt
    ) external {
        (uint256 nftId, ,) = IFluidVault(_vault).operateT1(0, _newCol, _newDebt, _recipient);
        IERC721(_nft).safeTransferFrom(address(this), _recipient, nftId);
    }
    
    function depositNewPositionT2(
        address _nft, 
        address _vault, 
        address _recipient,
        int256 newColToken0_,
        int256 newColToken1_,
        int256 colSharesMinMax_,
        int256 newDebt_
    ) external {
        (uint256 nftId, ,) =IFluidVault(_vault).operateT2(0, newColToken0_, newColToken1_, colSharesMinMax_, newDebt_, _recipient);
        IERC721(_nft).safeTransferFrom(address(this), _recipient, nftId);
    }

    function depositNewPositionT3(
        address _nft, 
        address _vault, 
        address _recipient,
        int256 _newCol,
        int256 _newDebtToken0,
        int256 _newDebtToken1,
        int256 _debtSharesMinMax
    ) external {
        (uint256 nftId, ,) = IFluidVault(_vault).operateT3(0, _newCol, _newDebtToken0, _newDebtToken1, _debtSharesMinMax, _recipient);
        IERC721(_nft).safeTransferFrom(address(this), _recipient, nftId);
    }
 
    function depositNewPositionT4(
        address _nft, 
        address _vault, 
        address _recipient,
        int256 _newColToken0,
        int256 _newColToken1,
        int256 _colSharesMinMax,
        int256 _newDebtToken0,
        int256 _newDebtToken1,
        int256 _debtSharesMinMax
    ) external {
        (uint256 nftId, ,) = IFluidVault(_vault).operateT4(0, _newColToken0, _newColToken1, _colSharesMinMax, _newDebtToken0, _newDebtToken1, _debtSharesMinMax, _recipient);
        IERC721(_nft).safeTransferFrom(address(this), _recipient, nftId);
    }
}

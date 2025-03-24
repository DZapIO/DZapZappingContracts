// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IFluidVaultT1 } from "../../interfaces/external/fluid/IFluidVaultT1.sol";
import { IFluidVaultT2 } from "../../interfaces/external/fluid/IFluidVaultT2.sol";
import { IFluidVaultT3 } from "../../interfaces/external/fluid/IFluidVaultT3.sol";
import { IFluidVaultT4 } from "../../interfaces/external/fluid/IFluidVaultT4.sol";
import "hardhat/console.sol";

contract FluidVaultAdapter {
    function depositNewPositionT1(
        address _nft, 
        address _vault, 
        address _recipient,
        int256 _newCol, 
        int256 _newDebt,
        uint256 _nativeAmount
    ) external payable {
        console.log("depositNewPositionT1", _nativeAmount, msg.value);
        console.log("_vault", _vault, _nft);
        (uint256 nftId, ,) = IFluidVaultT1(_vault).operate{value: _nativeAmount}(0, _newCol, _newDebt, _recipient);
        console.log("nftId", nftId);
        console.log("owner", IERC721(_nft).ownerOf(nftId));
        IERC721(_nft).safeTransferFrom(address(this), _recipient, nftId);
    }
    
    function depositNewPositionT2(
        address _nft, 
        address _vault, 
        address _recipient,
        int256 _perfectColShares,
        int256 _colToken0MinMax,
        int256 _colToken1MinMax,
        int256 _newDebt,
        uint256 _nativeAmount
    ) external payable {
        console.log("depositNewPositionT3", _nativeAmount, msg.value);
        console.log("_vault", _vault, _nft);
        (uint256 nftId, ) = IFluidVaultT2(_vault).operatePerfect{value: _nativeAmount}(0, _perfectColShares, _colToken0MinMax, _colToken1MinMax, _newDebt, _recipient);
        console.log("nftId", _nft, nftId);
        console.log("owner", IERC721(_nft).ownerOf(nftId));
        IERC721(_nft).safeTransferFrom(address(this), _recipient, nftId);
    }
    function depositNewPositionT3(
        address _nft, 
        address _vault, 
        address _recipient,
        int256 _newCol,
        int256 _newDebtToken0,
        int256 _newDebtToken1,
        int256 _debtSharesMinMax,
        uint256 _nativeAmount
    ) external payable {
        console.log("depositNewPositionT3", _nativeAmount, msg.value);
        console.log("_vault", _vault, _nft);
        (uint256 nftId, ,) = IFluidVaultT3(_vault).operate{value: _nativeAmount}(0, _newCol, _newDebtToken0, _newDebtToken1, _debtSharesMinMax, _recipient);
        console.log("nftId", _nft, nftId);
        console.log("owner", IERC721(_nft).ownerOf(nftId));
        IERC721(_nft).safeTransferFrom(address(this), _recipient, nftId);
    }
 
    function depositNewPositionT4(
        address _nft, 
        address _vault, 
        address _recipient,
        int256 _perfectColShares,
        int256 _colToken0MinMax,
        int256 _colToken1MinMax,
        int256 _perfectDebtShares,
        int256 _debtToken0MinMax,
        int256 _debtToken1MinMax,
        uint256 _nativeAmount
    ) external payable {
        console.log("depositNewPositionT4", _nativeAmount, msg.value);
        console.log("_vault", _vault, _nft);
        (uint256 nftId,) = IFluidVaultT4(_vault).operatePerfect{value: _nativeAmount}(0, _perfectColShares, _colToken0MinMax, _colToken1MinMax, _perfectDebtShares, _debtToken0MinMax, _debtToken1MinMax, _recipient);
        console.log("nftId", _nft, nftId);
        console.log("owner", IERC721(_nft).ownerOf(nftId));
        IERC721(_nft).safeTransferFrom(address(this), _recipient, nftId);
    }
}
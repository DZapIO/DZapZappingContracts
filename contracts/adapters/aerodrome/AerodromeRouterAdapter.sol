// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { CallFailed } from "../../shared/Errors.sol";
import { IAerodromeRouter } from "../../interfaces/external/aerodrome/IAerodromeRouter.sol";

struct AddLiquidityData {
    address router;
    address recipient; // dzap wallet
    address token0;
    address token1;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    bool isStablePool;
}

struct SwapData {
    address callTo; // dZapSwap, zap, router, dex, aggregator
    bytes callData;
    uint256 nativeValue;
    uint256 minReturnAmount;
}

contract AerodromeRouterAdapter {
    using SafeERC20 for IERC20;

    /**
        zap 
            approve for swap
            swap in adapter
            take balance 
            update balance and add liquidity

     */
    function swapAndAddLiquidity(SwapData memory _swapData, AddLiquidityData memory _addLiquidityData) public payable {
        uint256 initialAmount0 = IERC20(_addLiquidityData.token0).balanceOf(address(this));
        uint256 initialAmount1 = IERC20(_addLiquidityData.token1).balanceOf(address(this));

        // swap (approved from zap)
        (bool success, bytes memory res) = _swapData.callTo.call{ value: _swapData.nativeValue }(_swapData.callData);
        require(success, CallFailed(res));

        // desired + return
        uint256 amount0 = IERC20(_addLiquidityData.token0).balanceOf(address(this)) - initialAmount0 + _addLiquidityData.amount0Desired;
        uint256 amount1 = IERC20(_addLiquidityData.token1).balanceOf(address(this)) - initialAmount1 + _addLiquidityData.amount1Desired;

        // approve (for add)
        IERC20(_addLiquidityData.token0).approve(_addLiquidityData.router, amount0);
        IERC20(_addLiquidityData.token1).approve(_addLiquidityData.router, amount1);

        IAerodromeRouter(_addLiquidityData.router).addLiquidity(_addLiquidityData.token0, _addLiquidityData.token1, _addLiquidityData.isStablePool, amount0, amount1, _addLiquidityData.amount0Min, _addLiquidityData.amount1Min, _addLiquidityData.recipient, block.timestamp);
    }
}

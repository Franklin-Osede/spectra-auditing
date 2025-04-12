// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./MockERC20.sol";
import "./MockCurvePool.sol";
import "../../src/libraries/CurvePoolUtil.sol";

/**
 * @title MockUser
 * @dev Simulates a user interacting with the Curve pool
 */
contract MockUser {
    function addLiquidity(
        MockCurvePool pool,
        MockERC20 token0,
        MockERC20 token1,
        uint256 amount0,
        uint256 amount1,
        uint256 lpAmount
    ) external {
        // Approve tokens
        token0.approve(address(pool), amount0);
        token1.approve(address(pool), amount1);
        
        // Simulate adding liquidity
        pool.simulateAddLiquidity(amount0, amount1, lpAmount);
    }
    
    function removeLiquidity(
        MockCurvePool pool,
        uint256 lpAmount,
        uint256 amount0,
        uint256 amount1
    ) external {
        // Approve LP tokens
        MockERC20(pool.token()).approve(address(pool), lpAmount);
        
        // Simulate removing liquidity
        pool.simulateRemoveLiquidity(lpAmount, amount0, amount1);
    }
    
    function getExpectedAmounts(
        CurvePoolUtil poolUtil,
        address curvePool,
        uint256 lpAmount
    ) external view returns (uint256[2] memory) {
        return poolUtil.previewRemoveLiquidity(curvePool, lpAmount);
    }
}
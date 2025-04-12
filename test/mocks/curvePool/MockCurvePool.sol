// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../../src/interfaces/ICurvePool.sol";
import "./MockERC20.sol";

/**
 * @title MockCurvePool
 * @dev Mock implementation of a Curve pool for testing the vulnerability
 */
contract MockCurvePool {
    mapping(uint256 => address) public coins;
    mapping(uint256 => uint256) public balances;
    
    MockERC20 public lpToken;
    uint256 public A;
    uint256 public gamma;
    uint256 public D;
    uint256 public price_scale;
    uint256 public fee_gamma;
    uint256 public mid_fee;
    uint256 public out_fee;
    uint256 public allowed_extra_profit;
    uint256 public adjustment_step;
    uint256 public admin_fee;
    uint256 public ma_half_time;
    uint256 public last_prices_timestamp;
    uint256 public last_prices_value;
    uint256 public future_A_gamma_time;
    uint256 public future_A_gamma;
    uint256 public initial_A_gamma_time;
    uint256 public initial_A_gamma;
    
    event LiquidityAdded(uint256 amount0, uint256 amount1, uint256 lpAmount);
    event LiquidityRemoved(uint256 lpAmount, uint256 amount0, uint256 amount1);
    event TokenSwapped(uint256 i, uint256 j, uint256 dx, uint256 dy);

    constructor(address coin0, address coin1) {
        coins[0] = coin0;
        coins[1] = coin1;
        lpToken = new MockERC20("Mock Curve LP", "mCrvLP", 18);
        
        // Initialize with some default values
        A = 100000; // A=100
        gamma = 10**16; // 0.01
        mid_fee = 4000000; // 0.04%
        out_fee = 40000000; // 0.4%
        allowed_extra_profit = 10**17; // 0.1
        fee_gamma = 5 * 10**15; // 0.005
        adjustment_step = 10**15; // 0.001
        admin_fee = 5 * 10**9; // 50%
        ma_half_time = 600; // 10 minutes
        price_scale = 10**18; // 1.0
    }

    function token() external view returns (address) {
        return address(lpToken);
    }

    // Function to simulate adding liquidity to the pool
    function simulateAddLiquidity(uint256 amount0, uint256 amount1, uint256 lpAmount) external {
        balances[0] += amount0;
        balances[1] += amount1;
        lpToken.mint(msg.sender, lpAmount);
        emit LiquidityAdded(amount0, amount1, lpAmount);
    }
    
    // Function to simulate removing liquidity from the pool
    function simulateRemoveLiquidity(uint256 lpAmount, uint256 amount0, uint256 amount1) external {
        require(lpToken.balanceOf(msg.sender) >= lpAmount, "Insufficient LP tokens");
        balances[0] -= amount0;
        balances[1] -= amount1;
        lpToken.burn(msg.sender, lpAmount);
        emit LiquidityRemoved(lpAmount, amount0, amount1);
    }
    
    // Function to manipulate pool balances via swap
    function simulateSwap(uint256 i, uint256 j, uint256 dx, uint256 dy) external {
        require(i < 2 && j < 2 && i != j, "Invalid indices");
        require(balances[i] + dx >= 0, "Negative balance not allowed");
        require(balances[j] >= dy, "Insufficient output balance");
        
        balances[i] += dx;
        balances[j] -= dy;
        
        emit TokenSwapped(i, j, dx, dy);
    }
    
    // Mocked Curve function to calculate expected LP tokens for given input amounts
    function calc_token_amount(uint256[2] calldata amounts) external view returns (uint256) {
        uint256 d0 = balances[0];
        uint256 d1 = balances[1];
        uint256 _totalSupply = lpToken.totalSupply();
        
        if (_totalSupply == 0) {
            return amounts[0] + amounts[1]; // Simplified for testing
        }
        
        // Simple pro-rata calculation for testing
        return (_totalSupply * (amounts[0] + amounts[1])) / (d0 + d1);
    }
    
    // Mocked Curve function to calculate expected tokens for withdrawing one token
    function calc_withdraw_one_coin(uint256 _token_amount, uint256 i) external view returns (uint256) {
        require(i < 2, "Invalid index");
        uint256 _totalSupply = lpToken.totalSupply();
        if (_totalSupply == 0) return 0;
        
        // Simple pro-rata calculation for testing
        return (balances[i] * _token_amount) / _totalSupply;
    }
    
    // Mocked Curve function to calculate expected output of a swap
    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256) {
        require(i < 2 && j < 2 && i != j, "Invalid indices");
        
        // Simplified Curve swap formula for testing
        // In a real Curve pool, this would use a complex formula involving A, gamma, etc.
        uint256 x = balances[i];
        uint256 y = balances[j];
        uint256 k = x * y; // Simplified xy=k model
        uint256 x_new = x + dx;
        uint256 y_new = k / x_new;
        uint256 dy = y - y_new;
        
        // Apply a fee
        dy = (dy * (10**10 - mid_fee)) / 10**10;
        
        return dy;
    }
    
    // The following functions are stub implementations to satisfy the interface
    function get_virtual_price() external view returns (uint256) {
        return 10**18; // 1.0
    }
    
    function fee() external view returns (uint256) {
        return mid_fee;
    }
    
    function last_prices() external view returns (uint256) {
        return last_prices_value;
    }
}
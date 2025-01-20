// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { LiquidityDeployer } from "src/LiquidityDeployer.sol";
import { LD } from "src/types/DataTypes.sol";
import { Integration_Test } from "test/integration/Integration.t.sol";

struct Vars {
    address actualACLManager;
    address expectedACLManager;
    uint256 actualEarlyUnwindThreshold;
    uint256 expectedEarlyUnwindThreshold;
    address actualFeeCalculator;
    address expectedFeeCalculator;
    address actualLiquidityPool;
    address expectedLiquidityPool;
    uint256 actualMaxDeploymentAmount;
    uint256 expectedMaxDeploymentAmount;
    uint256 actualMaxDuration;
    uint256 expectedMaxDuration;
    uint256 actualMinDeploymentAmount;
    uint256 expectedMinDeploymentAmount;
    uint256 actualMinDuration;
    uint256 expectedMinDuration;
    address actualReserve;
    address expectedReserve;
    uint256 actualReserveFactor;
    uint256 expectedReserveFactor;
    uint256 actualRewardFactor;
    uint256 expectedRewardFactor;
    uint256 actualSurplusFactor;
    uint256 expectedSurplusFactor;
}

contract Constructor_LiquidityDeployer_Integration_Concrete_Test is Integration_Test {
    function test_Constructor() external {
        Vars memory vars;
        // Make Sender the caller in this test.
        resetPrank({ msgSender: users.sender });

        // Construct the contract.
        LiquidityDeployer constructedLiquidityDeployer = new LiquidityDeployer(
            LD.ConstructorParam({
                aclManager_: address(aclManager),
                earlyUnwindThreshold_: defaults.EARLY_UNWIND_THRESHOLD(),
                feeCalculator_: address(feeCalculator),
                liquidityPool_: address(liquidityPool),
                maxDeploymentAmount_: defaults.MAX_LIQUIDITY_AMOUNT(),
                maxDuration_: defaults.MAX_LIQUIDITY_DURATION(),
                minDeploymentAmount_: defaults.MIN_LIQUIDITY_AMOUNT(),
                minDuration_: defaults.MIN_LIQUIDITY_DURATION(),
                reserve_: users.reserve,
                reserveFactor_: defaults.RESERVE_FACTOR(),
                rewardFactor_: defaults.REWARD_FACTOR(),
                rushSmartLock_: users.burn,
                surplusFactor_: defaults.SURPLUS_FACTOR()
            })
        );

        // Assert that the values were set correctly.
        vars.actualACLManager = constructedLiquidityDeployer.ACL_MANAGER();
        vars.expectedACLManager = address(aclManager);
        assertEq(vars.actualACLManager, vars.expectedACLManager, "ACL_MANAGER");

        vars.actualEarlyUnwindThreshold = constructedLiquidityDeployer.EARLY_UNWIND_THRESHOLD();
        vars.expectedEarlyUnwindThreshold = defaults.EARLY_UNWIND_THRESHOLD();
        assertEq(vars.actualEarlyUnwindThreshold, vars.expectedEarlyUnwindThreshold, "EARLY_UNWIND_THRESHOLD");

        vars.actualFeeCalculator = constructedLiquidityDeployer.feeCalculator();
        vars.expectedFeeCalculator = address(feeCalculator);
        assertEq(vars.actualFeeCalculator, vars.expectedFeeCalculator, "feeCalculator");

        vars.actualLiquidityPool = constructedLiquidityDeployer.LIQUIDITY_POOL();
        vars.expectedLiquidityPool = address(liquidityPool);
        assertEq(vars.actualLiquidityPool, vars.expectedLiquidityPool, "LIQUIDITY_POOL");

        vars.actualMaxDeploymentAmount = constructedLiquidityDeployer.MAX_DEPLOYMENT_AMOUNT();
        vars.expectedMaxDeploymentAmount = defaults.MAX_LIQUIDITY_AMOUNT();
        assertEq(vars.actualMaxDeploymentAmount, vars.expectedMaxDeploymentAmount, "MAX_DEPLOYMENT_AMOUNT");

        vars.actualMaxDuration = constructedLiquidityDeployer.MAX_DURATION();
        vars.expectedMaxDuration = defaults.MAX_LIQUIDITY_DURATION();
        assertEq(vars.actualMaxDuration, vars.expectedMaxDuration, "MAX_DURATION");

        vars.actualMinDeploymentAmount = constructedLiquidityDeployer.MIN_DEPLOYMENT_AMOUNT();
        vars.expectedMinDeploymentAmount = defaults.MIN_LIQUIDITY_AMOUNT();
        assertEq(vars.actualMinDeploymentAmount, vars.expectedMinDeploymentAmount, "MIN_DEPLOYMENT_AMOUNT");

        vars.actualMinDuration = constructedLiquidityDeployer.MIN_DURATION();
        vars.expectedMinDuration = defaults.MIN_LIQUIDITY_DURATION();
        assertEq(vars.actualMinDuration, vars.expectedMinDuration, "MIN_DURATION");

        address actualReserve = constructedLiquidityDeployer.RESERVE();
        address expectedReserve = users.reserve;
        assertEq(actualReserve, expectedReserve, "RESERVE");

        vars.actualReserveFactor = constructedLiquidityDeployer.RESERVE_FACTOR();
        vars.expectedReserveFactor = defaults.RESERVE_FACTOR();
        assertEq(vars.actualReserveFactor, vars.expectedReserveFactor, "RESERVE_FACTOR");

        vars.actualRewardFactor = constructedLiquidityDeployer.REWARD_FACTOR();
        vars.expectedRewardFactor = defaults.REWARD_FACTOR();
        assertEq(vars.actualRewardFactor, vars.expectedRewardFactor, "REWARD_FACTOR");

        vars.actualSurplusFactor = constructedLiquidityDeployer.SURPLUS_FACTOR();
        vars.expectedSurplusFactor = defaults.SURPLUS_FACTOR();
        assertEq(vars.actualSurplusFactor, vars.expectedSurplusFactor, "SURPLUS_FACTOR");

        address actualWETH = constructedLiquidityDeployer.WETH();
        address expectedWETH = address(liquidityPool.asset());
        assertEq(actualWETH, expectedWETH, "WETH");
    }
}

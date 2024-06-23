// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { LiquidityDeployerWETH } from "src/LiquidityDeployerWETH.sol";

import { Integration_Test } from "test/integration/Integration.t.sol";

struct Vars {
    bool actualHasRole;
    bool expectedHasRole;
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
}

contract Constructor_LiquidityDeployerWETH_Integration_Concrete_Test is Integration_Test {
    function test_Constructor() external {
        Vars memory vars;
        // Make Sender the caller in this test.
        changePrank({ msgSender: users.sender });

        // Expect the relevant event to be emitted.
        vm.expectEmit();
        emit RoleGranted({ role: DEFAULT_ADMIN_ROLE, account: users.admin, sender: users.sender });

        // Construct the contract.
        LiquidityDeployerWETH constructedLiquidityDeployerWETH = new LiquidityDeployerWETH({
            admin_: users.admin,
            earlyUnwindThreshold_: defaults.EARLY_UNWIND_THRESHOLD(),
            feeCalculator_: address(feeCalculator),
            liquidityPool_: address(liquidityPool),
            maxDeploymentAmount_: defaults.MAX_LIQUIDITY_AMOUNT(),
            maxDuration_: defaults.MAX_LIQUIDITY_DURATION(),
            minDeploymentAmount_: defaults.MIN_LIQUIDITY_AMOUNT(),
            minDuration_: defaults.MIN_LIQUIDITY_DURATION(),
            reserve_: users.reserve,
            reserveFactor_: defaults.RESERVE_FACTOR()
        });

        // Assert that the admin has been initialized.
        vars.actualHasRole =
            constructedLiquidityDeployerWETH.hasRole({ role: DEFAULT_ADMIN_ROLE, account: users.admin });
        vars.expectedHasRole = true;
        assertEq(vars.actualHasRole, vars.expectedHasRole, "DEFAULT_ADMIN_ROLE");

        // Assert that the values were set correctly.

        vars.actualEarlyUnwindThreshold = constructedLiquidityDeployerWETH.EARLY_UNWIND_THRESHOLD();
        vars.expectedEarlyUnwindThreshold = defaults.EARLY_UNWIND_THRESHOLD();
        assertEq(vars.actualEarlyUnwindThreshold, vars.expectedEarlyUnwindThreshold, "EARLY_UNWIND_THRESHOLD");

        vars.actualFeeCalculator = constructedLiquidityDeployerWETH.FEE_CALCULATOR();
        vars.expectedFeeCalculator = address(feeCalculator);
        assertEq(vars.actualFeeCalculator, vars.expectedFeeCalculator, "FEE_CALCULATOR");

        vars.actualLiquidityPool = constructedLiquidityDeployerWETH.LIQUIDITY_POOL();
        vars.expectedLiquidityPool = address(liquidityPool);
        assertEq(vars.actualLiquidityPool, vars.expectedLiquidityPool, "LIQUIDITY_POOL");

        vars.actualMaxDeploymentAmount = constructedLiquidityDeployerWETH.MAX_DEPLOYMENT_AMOUNT();
        vars.expectedMaxDeploymentAmount = defaults.MAX_LIQUIDITY_AMOUNT();
        assertEq(vars.actualMaxDeploymentAmount, vars.expectedMaxDeploymentAmount, "MAX_DEPLOYMENT_AMOUNT");

        vars.actualMaxDuration = constructedLiquidityDeployerWETH.MAX_DURATION();
        vars.expectedMaxDuration = defaults.MAX_LIQUIDITY_DURATION();
        assertEq(vars.actualMaxDuration, vars.expectedMaxDuration, "MAX_DURATION");

        vars.actualMinDeploymentAmount = constructedLiquidityDeployerWETH.MIN_DEPLOYMENT_AMOUNT();
        vars.expectedMinDeploymentAmount = defaults.MIN_LIQUIDITY_AMOUNT();
        assertEq(vars.actualMinDeploymentAmount, vars.expectedMinDeploymentAmount, "MIN_DEPLOYMENT_AMOUNT");

        vars.actualMinDuration = constructedLiquidityDeployerWETH.MIN_DURATION();
        vars.expectedMinDuration = defaults.MIN_LIQUIDITY_DURATION();
        assertEq(vars.actualMinDuration, vars.expectedMinDuration, "MIN_DURATION");

        address actualReserve = constructedLiquidityDeployerWETH.RESERVE();
        address expectedReserve = users.reserve;
        assertEq(actualReserve, expectedReserve, "RESERVE");

        vars.actualReserveFactor = constructedLiquidityDeployerWETH.RESERVE_FACTOR();
        vars.expectedReserveFactor = defaults.RESERVE_FACTOR();
        assertEq(vars.actualReserveFactor, vars.expectedReserveFactor, "RESERVE_FACTOR");

        address actualWETH = constructedLiquidityDeployerWETH.WETH();
        address expectedWETH = address(liquidityPool.asset());
        assertEq(actualWETH, expectedWETH, "WETH");
    }
}

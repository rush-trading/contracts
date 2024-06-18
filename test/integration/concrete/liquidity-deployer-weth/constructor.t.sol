// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { LiquidityDeployerWETH } from "src/LiquidityDeployerWETH.sol";

import { Base_Test } from "test/Base.t.sol";

contract Constructor_LiquidityDeployerWETH_Integration_Concrete_Test is Base_Test {
    function test_Constructor() external {
        // Make Sender the caller in this test.
        changePrank({ msgSender: users.sender });

        // Expect the relevant event to be emitted.
        vm.expectEmit();
        emit RoleGranted({ role: DEFAULT_ADMIN_ROLE, account: users.admin, sender: users.sender });

        // Deploy the contracts.
        deployCore();

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
        bool actualHasRole =
            constructedLiquidityDeployerWETH.hasRole({ role: DEFAULT_ADMIN_ROLE, account: users.admin });
        bool expectedHasRole = true;
        assertEq(actualHasRole, expectedHasRole, "DEFAULT_ADMIN_ROLE");

        // Assert that the values were set correctly.
        {
            uint256 actualEarlyUnwindThreshold = constructedLiquidityDeployerWETH.EARLY_UNWIND_THRESHOLD();
            uint256 expectedEarlyUnwindThreshold = defaults.EARLY_UNWIND_THRESHOLD();
            assertEq(actualEarlyUnwindThreshold, expectedEarlyUnwindThreshold, "EARLY_UNWIND_THRESHOLD");

            address actualFeeCalculator = constructedLiquidityDeployerWETH.FEE_CALCULATOR();
            address expectedFeeCalculator = address(feeCalculator);
            assertEq(actualFeeCalculator, expectedFeeCalculator, "FEE_CALCULATOR");

            address actualLiquidityPool = constructedLiquidityDeployerWETH.LIQUIDITY_POOL();
            address expectedLiquidityPool = address(liquidityPool);
            assertEq(actualLiquidityPool, expectedLiquidityPool, "LIQUIDITY_POOL");

            uint256 actualMaxDeploymentAmount = constructedLiquidityDeployerWETH.MAX_DEPLOYMENT_AMOUNT();
            uint256 expectedMaxDeploymentAmount = defaults.MAX_LIQUIDITY_AMOUNT();
            assertEq(actualMaxDeploymentAmount, expectedMaxDeploymentAmount, "MAX_DEPLOYMENT_AMOUNT");

            uint256 actualMaxDuration = constructedLiquidityDeployerWETH.MAX_DURATION();
            uint256 expectedMaxDuration = defaults.MAX_LIQUIDITY_DURATION();
            assertEq(actualMaxDuration, expectedMaxDuration, "MAX_DURATION");
        }
        {
            uint256 actualMinDeploymentAmount = constructedLiquidityDeployerWETH.MIN_DEPLOYMENT_AMOUNT();
            uint256 expectedMinDeploymentAmount = defaults.MIN_LIQUIDITY_AMOUNT();
            assertEq(actualMinDeploymentAmount, expectedMinDeploymentAmount, "MIN_DEPLOYMENT_AMOUNT");

            uint256 actualMinDuration = constructedLiquidityDeployerWETH.MIN_DURATION();
            uint256 expectedMinDuration = defaults.MIN_LIQUIDITY_DURATION();
            assertEq(actualMinDuration, expectedMinDuration, "MIN_DURATION");

            address actualReserve = constructedLiquidityDeployerWETH.RESERVE();
            address expectedReserve = users.reserve;
            assertEq(actualReserve, expectedReserve, "RESERVE");

            uint256 actualReserveFactor = constructedLiquidityDeployerWETH.RESERVE_FACTOR();
            uint256 expectedReserveFactor = defaults.RESERVE_FACTOR();
            assertEq(actualReserveFactor, expectedReserveFactor, "RESERVE_FACTOR");

            address actualWETH = constructedLiquidityDeployerWETH.WETH();
            address expectedWETH = address(liquidityPool.asset());
            assertEq(actualWETH, expectedWETH, "WETH");
        }
    }
}

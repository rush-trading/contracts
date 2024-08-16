// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { LiquidityPool_Integration_Concrete_Test } from "./../LiquidityPool.t.sol";

contract SetMaxTotalDeposits_Integration_Concrete_Test is LiquidityPool_Integration_Concrete_Test {
    function test_RevertWhen_CallerDoesNotHaveAdminRole() external {
        // Set Eve as the caller.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.OnlyAdminRole.selector, users.eve));
        liquidityPool.setMaxTotalDeposits(0);
    }

    modifier whenCallerHasAdminRole() {
        // Set Admin as the caller.
        resetPrank({ msgSender: users.admin });
        _;
    }

    function test_RevertWhen_AmountIsZero() external whenCallerHasAdminRole {
        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityPool_ZeroAmount.selector));
        liquidityPool.setMaxTotalDeposits(0);
    }

    function test_WhenAmountIsNotZero() external whenCallerHasAdminRole {
        // Expect the relevant event to be emitted.
        uint256 amount = defaults.MAX_TOTAL_DEPOSITS();
        vm.expectEmit({ emitter: address(liquidityPool) });
        emit SetMaxTotalDeposits({ newMaxTotalDeposits: amount });

        // Set the max total deposits.
        liquidityPool.setMaxTotalDeposits(amount);

        // Assert that the max total deposits were set correctly.
        uint256 actualMaxTotalDeposits = liquidityPool.maxTotalDeposits();
        uint256 expectedMaxTotalDeposits = amount;
        assertEq(actualMaxTotalDeposits, expectedMaxTotalDeposits, "maxTotalDeposits");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { LiquidityDeployer_Fork_Test } from "../LiquidityDeployer.t.sol";

contract SetFeeCalculatortsol_Fork_Test is LiquidityDeployer_Fork_Test {
    function test_RevertWhen_CallerDoesNotHaveAdminRole() external {
        // Set Eve as the caller.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.OnlyAdminRole.selector, users.eve));
        liquidityDeployer.setFeeCalculator(address(1));
    }

    modifier whenCallerHasAdminRole() {
        // Set Admin as the caller.
        resetPrank({ msgSender: users.admin });
        _;
    }

    function test_RevertWhen_ContractIsNotPaused() external whenCallerHasAdminRole {
        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.ExpectedPause.selector));
        liquidityDeployer.setFeeCalculator(address(1));
    }

    modifier whenContractIsPaused() {
        // Pause the contract.
        liquidityDeployer.pause();
        _;
    }

    function test_RevertWhen_NewFeeCalculatorIsZeroAddress() external whenCallerHasAdminRole whenContractIsPaused {
        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_FeeCalculatorZeroAddress.selector));
        liquidityDeployer.setFeeCalculator(address(0));
    }

    function test_WhenNewFeeCalculatorIsNotZeroAddress() external whenCallerHasAdminRole whenContractIsPaused {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(liquidityDeployer) });
        emit SetFeeCalculator({ newFeeCalculator: address(1) });

        // Set the new fee calculator.
        liquidityDeployer.setFeeCalculator(address(1));

        // Assert that the new fee calculator is set.
        address actualFeeCalculator = liquidityDeployer.feeCalculator();
        address expectedFeeCalculator = address(1);
        vm.assertEq(actualFeeCalculator, expectedFeeCalculator, "feeCalculator");
    }
}

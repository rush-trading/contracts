// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { LiquidityPool_Integration_Concrete_Test } from "../LiquidityPool.t.sol";

contract DispatchAsset_Integration_Concrete_Test is LiquidityPool_Integration_Concrete_Test {
    function test_RevertWhen_CallerDoesNotHaveAssetManagerRole() external {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.AccessControlUnauthorizedAccount.selector, users.eve, ASSET_MANAGER_ROLE)
        );
        liquidityPool.dispatchAsset({ to: users.recipient, amount: 1, data: "" });
    }

    modifier whenCallerHasAssetManagerRole() {
        // Make DispatchAssetCaller the caller in this test.
        changePrank({ msgSender: address(dispatchAssetCaller) });
        _;
    }

    function test_RevertWhen_AssetRecipientIsZeroAddress() external whenCallerHasAssetManagerRole {
        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityPool_ZeroAddress.selector));
        liquidityPool.dispatchAsset({ to: address(0), amount: 1, data: "" });
    }

    modifier whenAssetRecipientIsNotZeroAddress() {
        _;
    }

    function test_RevertWhen_AmountIsZero() external whenCallerHasAssetManagerRole whenAssetRecipientIsNotZeroAddress {
        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityPool_ZeroAmount.selector));
        liquidityPool.dispatchAsset({ to: users.recipient, amount: 0, data: "" });
    }

    function test_WhenAmountIsNotZero() external whenCallerHasAssetManagerRole whenAssetRecipientIsNotZeroAddress {
        // Add deposits to the pool.
        depositToLiquidityPool(defaults.DEPOSIT_AMOUNT());

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(liquidityPool) });
        emit DispatchAsset({
            originator: address(dispatchAssetCaller),
            to: users.recipient,
            amount: defaults.DEPOSIT_AMOUNT()
        });

        // Dispatch the asset.
        uint256 beforeBalance = wethMock.balanceOf(users.recipient);
        liquidityPool.dispatchAsset({ to: users.recipient, amount: defaults.DEPOSIT_AMOUNT(), data: "" });
        uint256 afterBalance = wethMock.balanceOf(users.recipient);

        // Assert that the asset has been dispatched.
        uint256 actualAssetReceived = afterBalance - beforeBalance;
        uint256 expectedAssetReceived = defaults.DEPOSIT_AMOUNT();
        assertEq(actualAssetReceived, expectedAssetReceived, "balanceOf");
    }
}

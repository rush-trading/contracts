// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { LiquidityPool_Integration_Concrete_Test } from "../LiquidityPool.t.sol";

contract ReturnAsset_Integration_Concrete_Test is LiquidityPool_Integration_Concrete_Test {
    function test_RevertWhen_CallerDoesNotHaveAssetManagerRole() external {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.AccessControlUnauthorizedAccount.selector, users.eve, ASSET_MANAGER_ROLE)
        );
        liquidityPool.returnAsset({ from: users.recipient, amount: 1, data: "" });
    }

    modifier whenCallerHasAssetManagerRole() {
        // Make ReturnAssetCaller the caller in this test.
        changePrank({ msgSender: address(returnAssetCaller) });
        _;
    }

    function test_RevertWhen_AssetSenderIsZeroAddress() external whenCallerHasAssetManagerRole {
        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityPool_ZeroAddress.selector));
        liquidityPool.returnAsset({ from: address(0), amount: 1, data: "" });
    }

    modifier whenAssetSenderIsNotZeroAddress() {
        _;
    }

    function test_RevertWhen_AmountIsZero() external whenCallerHasAssetManagerRole whenAssetSenderIsNotZeroAddress {
        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityPool_ZeroAmount.selector));
        liquidityPool.returnAsset({ from: users.sender, amount: 0, data: "" });
    }

    function test_WhenAmountIsNotZero() external whenCallerHasAssetManagerRole whenAssetSenderIsNotZeroAddress {
        // Add deposits to the pool.
        depositToLiquidityPool(defaults.DEPOSIT_AMOUNT());

        // Dispatch the asset.
        dispatchFromLiquidityPool(defaults.DISPATCH_AMOUNT());

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(liquidityPool) });
        emit ReturnAsset({
            originator: address(returnAssetCaller),
            from: users.sender,
            amount: defaults.DISPATCH_AMOUNT()
        });

        // Dispatch the asset.
        uint256 beforeBalance = weth.balanceOf(users.sender);
        liquidityPool.returnAsset({ from: users.sender, amount: defaults.DISPATCH_AMOUNT(), data: "" });
        uint256 afterBalance = weth.balanceOf(users.sender);

        // Assert that the asset has been dispatched.
        uint256 actualAssetSent = beforeBalance - afterBalance;
        uint256 expectedAssetSent = defaults.DISPATCH_AMOUNT();
        assertEq(actualAssetSent, expectedAssetSent, "balanceOf");
    }
}

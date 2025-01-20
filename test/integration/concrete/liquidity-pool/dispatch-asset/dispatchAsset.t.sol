// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { LiquidityPool_Integration_Concrete_Test } from "../LiquidityPool.t.sol";

contract DispatchAsset_Integration_Concrete_Test is LiquidityPool_Integration_Concrete_Test {
    function test_RevertWhen_CallerDoesNotHaveAssetManagerRole() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        uint256 amount = defaults.LIQUIDITY_AMOUNT();
        vm.expectRevert(abi.encodeWithSelector(Errors.OnlyAssetManagerRole.selector, users.eve));
        liquidityPool.dispatchAsset({ to: users.recipient, amount: amount });
    }

    modifier whenCallerHasAssetManagerRole() {
        // Make AssetManager the caller in this test.
        resetPrank({ msgSender: users.assetManager });
        _;
    }

    function test_RevertWhen_AssetRecipientIsZeroAddress() external whenCallerHasAssetManagerRole {
        // Run the test.
        uint256 amount = defaults.LIQUIDITY_AMOUNT();
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityPool_ZeroAddress.selector));
        liquidityPool.dispatchAsset({ to: address(0), amount: amount });
    }

    modifier whenAssetRecipientIsNotZeroAddress() {
        _;
    }

    function test_RevertWhen_AssetRecipientIsLiquidityPoolItself()
        external
        whenCallerHasAssetManagerRole
        whenAssetRecipientIsNotZeroAddress
    {
        // Run the test.
        uint256 amount = defaults.LIQUIDITY_AMOUNT();
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityPool_SelfDispatch.selector));
        liquidityPool.dispatchAsset({ to: address(liquidityPool), amount: amount });
    }

    modifier whenAssetRecipientIsNotLiquidityPoolItself() {
        _;
    }

    function test_RevertWhen_AmountIsZero()
        external
        whenCallerHasAssetManagerRole
        whenAssetRecipientIsNotZeroAddress
        whenAssetRecipientIsNotLiquidityPoolItself
    {
        // Run the test.
        uint256 amount = 0;
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityPool_ZeroAmount.selector));
        liquidityPool.dispatchAsset({ to: users.recipient, amount: amount });
    }

    function test_WhenAmountIsNotZero()
        external
        whenCallerHasAssetManagerRole
        whenAssetRecipientIsNotZeroAddress
        whenAssetRecipientIsNotLiquidityPoolItself
    {
        // Add deposits to LiquidityPool.
        deposit({ asset: address(wethMock), amount: defaults.DEPOSIT_AMOUNT() });

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(liquidityPool) });
        emit DispatchAsset({ originator: users.assetManager, to: users.recipient, amount: defaults.DEPOSIT_AMOUNT() });

        // Dispatch the asset.
        uint256 beforeBalance = wethMock.balanceOf(users.recipient);
        liquidityPool.dispatchAsset({ to: users.recipient, amount: defaults.DEPOSIT_AMOUNT() });
        uint256 afterBalance = wethMock.balanceOf(users.recipient);

        // Assert that the asset has been dispatched.
        uint256 actualAssetReceived = afterBalance - beforeBalance;
        uint256 expectedAssetReceived = defaults.DEPOSIT_AMOUNT();
        assertEq(actualAssetReceived, expectedAssetReceived, "balanceOf");
    }
}

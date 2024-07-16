// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { LiquidityPool_Integration_Concrete_Test } from "../LiquidityPool.t.sol";

contract ReturnAsset_Integration_Concrete_Test is LiquidityPool_Integration_Concrete_Test {
    function test_RevertWhen_CallerDoesNotHaveAssetManagerRole() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        uint256 amount = defaults.LIQUIDITY_AMOUNT();
        vm.expectRevert(
            abi.encodeWithSelector(Errors.AccessControlUnauthorizedAccount.selector, users.eve, ASSET_MANAGER_ROLE)
        );
        liquidityPool.returnAsset({ from: users.recipient, amount: amount, data: "" });
    }

    modifier whenCallerHasAssetManagerRole() {
        // Make ReturnAssetCaller the caller in this test.
        resetPrank({ msgSender: address(returnAssetCaller) });
        _;
    }

    function test_RevertWhen_AssetSenderIsZeroAddress() external whenCallerHasAssetManagerRole {
        // Run the test.
        uint256 amount = defaults.LIQUIDITY_AMOUNT();
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityPool_ZeroAddress.selector));
        liquidityPool.returnAsset({ from: address(0), amount: amount, data: "" });
    }

    modifier whenAssetSenderIsNotZeroAddress() {
        _;
    }

    function test_RevertWhen_AssetSenderIsLiquidityPoolItself()
        external
        whenCallerHasAssetManagerRole
        whenAssetSenderIsNotZeroAddress
    {
        // Run the test.
        uint256 amount = defaults.LIQUIDITY_AMOUNT();
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityPool_SelfReturn.selector));
        liquidityPool.returnAsset({ from: address(liquidityPool), amount: amount, data: "" });
    }

    modifier whenAssetSenderIsNotLiquidityPoolItself() {
        _;
    }

    function test_RevertWhen_AmountIsZero()
        external
        whenCallerHasAssetManagerRole
        whenAssetSenderIsNotZeroAddress
        whenAssetSenderIsNotLiquidityPoolItself
    {
        // Run the test.
        uint256 amount = 0;
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityPool_ZeroAmount.selector));
        liquidityPool.returnAsset({ from: users.sender, amount: amount, data: "" });
    }

    function test_WhenAmountIsNotZero()
        external
        whenCallerHasAssetManagerRole
        whenAssetSenderIsNotZeroAddress
        whenAssetSenderIsNotLiquidityPoolItself
    {
        // Add deposits to the pool.
        deposit({ asset: address(wethMock), amount: defaults.DEPOSIT_AMOUNT() });

        // Dispatch the asset.
        uint256 amount = defaults.LIQUIDITY_AMOUNT();
        dispatchAsset(amount);

        // Supply the asset to the Sender.
        deal({ token: address(wethMock), to: users.sender, give: amount });

        // Approve the LiquidityPool to spend the asset on behalf of the Sender.
        approveFrom({ asset: address(wethMock), owner: users.sender, spender: address(liquidityPool), amount: amount });

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(liquidityPool) });
        emit ReturnAsset({ originator: address(returnAssetCaller), from: users.sender, amount: amount });

        // Return the asset.
        uint256 beforeBalance = wethMock.balanceOf(users.sender);
        liquidityPool.returnAsset({ from: users.sender, amount: amount, data: "" });
        uint256 afterBalance = wethMock.balanceOf(users.sender);

        // Assert that the asset has been dispatched.
        uint256 actualAssetSent = beforeBalance - afterBalance;
        uint256 expectedAssetSent = amount;
        assertEq(actualAssetSent, expectedAssetSent, "balanceOf");
    }
}

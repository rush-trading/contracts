// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { LiquidityPool_Integration_Concrete_Test } from "../LiquidityPool.t.sol";

contract TotalAssets_Integration_Concrete_Test is LiquidityPool_Integration_Concrete_Test {
    function test_GivenPoolHasNeverReceivedDeposits() external view {
        uint256 actualTotalAssets = liquidityPool.totalAssets();
        uint256 expectedTotalAssets = 0;
        assertEq(actualTotalAssets, expectedTotalAssets, "totalAssets");
    }

    modifier givenPoolHasReceivedDeposits() {
        deposit({ asset: address(wethMock), amount: defaults.DEPOSIT_AMOUNT() });
        _;
    }

    function test_GivenPoolHasReceivedDepositsButNoDispatches() external givenPoolHasReceivedDeposits {
        uint256 actualTotalAssets = liquidityPool.totalAssets();
        uint256 expectedTotalAssets = defaults.DEPOSIT_AMOUNT();
        assertEq(actualTotalAssets, expectedTotalAssets, "totalAssets");
    }

    function test_GivenPoolHasReceivedDepositsAndDispatches() external givenPoolHasReceivedDeposits {
        resetPrank({ msgSender: address(dispatchAssetCaller) });
        liquidityPool.dispatchAsset({ to: users.recipient, amount: defaults.DISPATCH_AMOUNT(), data: "" });

        uint256 actualTotalAssets = liquidityPool.totalAssets();
        uint256 expectedTotalAssets = defaults.DISPATCH_AMOUNT() + wethMock.balanceOf(address(liquidityPool));
        assertEq(actualTotalAssets, expectedTotalAssets, "totalAssets");
    }

    function test_GivenPoolHasReceivedDepositsAndAllAreDispatched() external givenPoolHasReceivedDeposits {
        resetPrank({ msgSender: address(dispatchAssetCaller) });
        liquidityPool.dispatchAsset({ to: users.recipient, amount: defaults.DEPOSIT_AMOUNT(), data: "" });

        uint256 actualTotalAssets = liquidityPool.totalAssets();
        uint256 expectedTotalAssets = defaults.DEPOSIT_AMOUNT();
        assertEq(actualTotalAssets, expectedTotalAssets, "totalAssets");
    }
}

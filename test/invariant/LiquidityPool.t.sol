// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { LiquidityPool } from "src/LiquidityPool.sol";

import { Invariant_Test } from "./Invariant.t.sol";
import { LiquidityPoolHandler } from "./handlers/LiquidityPoolHandler.sol";
import { LiquidityPoolStore } from "./stores/LiquidityPoolStore.sol";

/// @dev Invariant tests for {LiquidityPool}.
contract LiquidityPool_Invariant_Test is Invariant_Test {
    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    LiquidityPoolHandler internal liquidityPoolHandler;
    LiquidityPoolStore internal liquidityPoolStore;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ SET-UP FUNCTION +|=------------------------------- //

    function setUp() public virtual override {
        Invariant_Test.setUp();
        deploy();
        grantRoles();

        // Target the LiquidityPool handler for invariant testing.
        targetContract(address(liquidityPoolHandler));

        // Prevent these contracts from being fuzzed as `msg.sender`.
        excludeSender(address(liquidityPool));
        excludeSender(address(liquidityPoolHandler));
        excludeSender(address(liquidityPoolStore));
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Deploys the contract.
    function deploy() internal {
        liquidityPool = new LiquidityPool({ aclManager_: address(aclManager), asset_: address(wethMock) });
        vm.label({ account: address(liquidityPool), newLabel: "LiquidityPool" });
        liquidityPoolStore = new LiquidityPoolStore();
        vm.label({ account: address(liquidityPoolStore), newLabel: "LiquidityPoolStore" });
        liquidityPoolHandler =
            new LiquidityPoolHandler({ liquidityPool_: liquidityPool, liquidityPoolStore_: liquidityPoolStore });
        vm.label({ account: address(liquidityPoolHandler), newLabel: "LiquidityPoolHandler" });
    }

    /// @dev Grants roles.
    function grantRoles() internal {
        (, address caller,) = vm.readCallers();
        resetPrank(users.admin);
        aclManager.addAssetManager({ account: address(liquidityPoolHandler) });
        resetPrank(caller);
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ INVARIANTS +|=---------------------------------- //

    function invariant_balanceIsConsistent() external view {
        assertEq(wethMock.balanceOf(address(liquidityPool)), liquidityPoolStore.balance());
    }

    function invariant_balanceLeTotalAssets() external view {
        assertLe(wethMock.balanceOf(address(liquidityPool)), liquidityPoolStore.totalAssets());
    }

    function invariant_outstandingAssetsIsConsistent() external view {
        assertEq(liquidityPool.outstandingAssets(), liquidityPoolStore.outstandingAssets());
    }

    function invariant_outstandingAssetsLeTotalAssets() external view {
        assertLe(liquidityPool.outstandingAssets(), liquidityPoolStore.totalAssets());
    }

    function invariant_totalAssetsEqSumOfOutstandingAndBalance() external view {
        assertEq(liquidityPool.totalAssets(), liquidityPoolStore.outstandingAssets() + liquidityPoolStore.balance());
    }

    function invariant_totalAssetsIsConsistent() external view {
        assertEq(liquidityPool.totalAssets(), liquidityPoolStore.totalAssets());
    }

    function invariant_totalAssetsGeBalance() external view {
        assertGe(liquidityPool.totalAssets(), liquidityPoolStore.balance());
    }

    function invariant_totalAssetsGeOutstandingAssets() external view {
        assertGe(liquidityPool.totalAssets(), liquidityPoolStore.outstandingAssets());
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

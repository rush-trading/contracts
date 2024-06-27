// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { LiquidityPool } from "src/LiquidityPool.sol";

import { Invariant_Test } from "./Invariant.t.sol";
import { LiquidityPoolHandler } from "./handlers/LiquidityPoolHandler.sol";

/// @dev Invariant tests for {LiquidityPool}.
contract LiquidityPool_Invariant_Test is Invariant_Test {
    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    LiquidityPoolHandler internal liquidityPoolHandler;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ SET-UP FUNCTION +|=------------------------------- //

    function setUp() public virtual override {
        Invariant_Test.setUp();
        deploy();
        grantRoles();

        // Target the LiquidityPool handler for invariant testing.
        targetContract(address(liquidityPoolHandler));

        // Prevent these contracts from being fuzzed as `msg.sender`.
        excludeSender(address(liquidityPoolHandler));
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Deploys the contract.
    function deploy() internal {
        liquidityPool = new LiquidityPool({ admin_: users.admin, asset_: address(wethMock) });
        liquidityPoolHandler = new LiquidityPoolHandler(liquidityPool);
    }

    /// @dev Grants roles.
    function grantRoles() internal {
        (, address caller,) = vm.readCallers();
        resetPrank(users.admin);
        liquidityPool.grantRole({ role: ASSET_MANAGER_ROLE, account: address(liquidityPoolHandler) });
        resetPrank(caller);
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ INVARIANTS +|=---------------------------------- //

    function invariant_totalAssetsEqSumOfOutstandingAndBalance() external view {
        assertEq(
            liquidityPool.totalAssets(), liquidityPool.outstandingAssets() + wethMock.balanceOf(address(liquidityPool))
        );
    }

    function invariant_totalAssetsGeBalance() external view {
        assertGe(liquidityPool.totalAssets(), wethMock.balanceOf(address(liquidityPool)));
    }

    function invariant_totalAssetsGeOutstandingAssets() external view {
        assertGe(liquidityPool.totalAssets(), liquidityPool.outstandingAssets());
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

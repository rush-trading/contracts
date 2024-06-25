// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { LiquidityPool } from "src/LiquidityPool.sol";

import { Integration_Test } from "test/integration/Integration.t.sol";

import { DispatchAssetCaller } from "test/mocks/DispatchAssetCaller.sol";
import { ReturnAssetCaller } from "test/mocks/ReturnAssetCaller.sol";

contract LiquidityPool_Integration_Concrete_Test is Integration_Test {
    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    DispatchAssetCaller internal dispatchAssetCaller;
    ReturnAssetCaller internal returnAssetCaller;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ SET-UP FUNCTION +|=------------------------------- //

    function setUp() public virtual override {
        Integration_Test.setUp();
        deploy();
        grantRoles();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Deploys the contract.
    function deploy() internal {
        dispatchAssetCaller = new DispatchAssetCaller();
        vm.label({ account: address(dispatchAssetCaller), newLabel: "DispatchAssetCaller" });
        returnAssetCaller = new ReturnAssetCaller();
        vm.label({ account: address(returnAssetCaller), newLabel: "ReturnAssetCaller" });
    }

    /// @dev Dispatches assets from the liquidity pool to the Recipient.
    function dispatchAsset(uint256 amount) internal {
        (, address caller,) = vm.readCallers();
        resetPrank({ msgSender: address(dispatchAssetCaller) });
        liquidityPool.dispatchAsset({ to: users.recipient, amount: amount, data: "" });
        resetPrank({ msgSender: caller });
    }

    /// @dev Grants roles.
    function grantRoles() internal {
        (, address caller,) = vm.readCallers();
        resetPrank({ msgSender: users.admin });
        liquidityPool.grantRole({ role: ASSET_MANAGER_ROLE, account: address(dispatchAssetCaller) });
        liquidityPool.grantRole({ role: ASSET_MANAGER_ROLE, account: address(returnAssetCaller) });
        resetPrank({ msgSender: caller });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

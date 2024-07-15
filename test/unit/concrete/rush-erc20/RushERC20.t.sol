// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { GoodRushERC20Mock } from "test/mocks/GoodRushERC20Mock.sol";

import { Base_Test } from "test/Base.t.sol";

contract RushERC20_Unit_Concrete_Test is Base_Test {
    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    GoodRushERC20Mock internal rushERC20Mock;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ SET-UP FUNCTION +|=------------------------------- //

    function setUp() public virtual override {
        Base_Test.setUp();
        deploy();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Deploys the contract.
    function deploy() internal {
        rushERC20Mock = new GoodRushERC20Mock();
        vm.label({ account: address(rushERC20Mock), newLabel: "RushERC20Mock" });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

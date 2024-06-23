// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { GoodRushERC20Mock } from "test/mocks/GoodRushERC20Mock.sol";
import { BadRushERC20Mock } from "test/mocks/BadRushERC20Mock.sol";

import { Integration_Test } from "test/integration/Integration.t.sol";

contract RushERC20Factory_Integration_Concrete_Test is Integration_Test {
    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    GoodRushERC20Mock internal goodRushERC20Mock;
    BadRushERC20Mock internal badRushERC20Mock;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ SET-UP FUNCTION +|=------------------------------- //

    function setUp() public virtual override {
        Integration_Test.setUp();
        deploy();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Deploys the contracts.
    function deploy() internal {
        goodRushERC20Mock = new GoodRushERC20Mock();
        vm.label({ account: address(goodRushERC20Mock), newLabel: "GoodRushERC20Mock" });
        badRushERC20Mock = new BadRushERC20Mock();
        vm.label({ account: address(badRushERC20Mock), newLabel: "BadRushERC20Mock" });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

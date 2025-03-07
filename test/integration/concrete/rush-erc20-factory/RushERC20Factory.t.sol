// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { Integration_Test } from "test/integration/Integration.t.sol";
import { BadRushERC20Mock } from "test/mocks/BadRushERC20Mock.sol";
import { GoodRushERC20Mock } from "test/mocks/GoodRushERC20Mock.sol";

contract RushERC20Factory_Integration_Concrete_Test is Integration_Test {
    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    GoodRushERC20Mock internal goodRushERC20Mock;
    BadRushERC20Mock internal badRushERC20Mock;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ VARIABLES +|=----------------------------------- //

    string internal templateDescription;
    bytes32 internal templateKind;
    uint256 internal templateVersion;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ SET-UP FUNCTION +|=------------------------------- //

    function setUp() public virtual override {
        Integration_Test.setUp();
        deploy();

        templateDescription = goodRushERC20Mock.description();
        templateKind = keccak256(abi.encodePacked(templateDescription));
        templateVersion = goodRushERC20Mock.version();
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

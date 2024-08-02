// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { IRushERC20 } from "src/interfaces/IRushERC20.sol";
import { RushERC20Basic } from "src/tokens/RushERC20Basic.sol";

import { Integration_Test } from "test/integration/Integration.t.sol";

contract RushERC20Basic_Integration_Shared_Test is Integration_Test {
    // #region --------------------------------=|+ SET-UP FUNCTION +|=------------------------------- //

    function setUp() public virtual override {
        Integration_Test.setUp();
        deploy();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Deploys the contract.
    function deploy() internal {
        address implementation = address(new RushERC20Basic());
        addTemplate({ implementation: implementation });
        rushERC20 = IRushERC20(createRushERC20({ implementation: implementation }));
        vm.label({ account: address(rushERC20), newLabel: "RushERC20Basic" });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

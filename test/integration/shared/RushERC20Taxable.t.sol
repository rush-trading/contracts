// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;
import { IRushERC20 } from "src/interfaces/IRushERC20.sol";
import { RushERC20Taxable } from "src/tokens/RushERC20Taxable.sol";
import { Integration_Test } from "test/integration/Integration.t.sol";

contract Rush_ERC20_Taxable_Integration_Shared_Test is Integration_Test {
    // #region --------------------------------=|+ SET-UP FUNCTION +|=------------------------------- //

    function setUp() public virtual override {
        Integration_Test.setUp();
        deploy();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Deploys the contract.
    function deploy() internal {
        address implementation = address(new RushERC20Taxable());
        addTemplate({ implementation: implementation });
        rushERC20 = IRushERC20(createRushERC20({ implementation: implementation }));
        vm.label({ account: address(rushERC20), newLabel: "RushERC20Taxable" });
    }

    // #endregion ----------------------------------------------------------------------------------- //

}

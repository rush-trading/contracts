// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { ACLManager } from "src/ACLManager.sol";
import { Base_Test } from "test/Base.t.sol";

contract ACLManager_Unit_Concrete_Test is Base_Test {
    // #region --------------------------------=|+ SET-UP FUNCTION +|=------------------------------- //

    function setUp() public virtual override {
        Base_Test.setUp();
        deploy();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Deploys the contract.
    function deploy() internal {
        aclManager = new ACLManager({ admin_: users.admin });
        vm.label({ account: address(aclManager), newLabel: "ACLManager" });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

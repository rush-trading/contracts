// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { RushERC20Basic } from "src/tokens/RushERC20Basic.sol";

import { Base_Test } from "test/Base.t.sol";

contract RushERC20Basic_Unit_Concrete_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
        deploy();
    }

    /// @dev Deploys the contract.
    function deploy() internal {
        rushERC20 = new RushERC20Basic();
        vm.label({ account: address(rushERC20), newLabel: "RushERC20Basic" });
    }
}

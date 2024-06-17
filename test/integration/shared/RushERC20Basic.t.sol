// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { IRushERC20 } from "src/interfaces/IRushERC20.sol";
import { RushERC20Basic } from "src/tokens/RushERC20Basic.sol";

import { Integration_Test } from "test/integration/Integration.t.sol";

contract RushERC20Basic_Integration_Shared_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();
        deploy();
    }

    /// @dev Deploys the contract.
    function deploy() internal {
        addTemplateToFactory({ implementation: address(new RushERC20Basic()) });
        rushERC20 = IRushERC20(createERC20FromFactory({ kind: keccak256("RushERC20Basic") }));
        vm.label({ account: address(rushERC20), newLabel: "RushERC20Basic" });
    }
}

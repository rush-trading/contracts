// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { StakingRewards } from "src/StakingRewards.sol";
import { Base_Test } from "test/Base.t.sol";

contract Constructor_StakingRewards_Unit_Concrete_Test is Base_Test {
    function test_Constructor() external {
        // Construct the implementation contract.
        StakingRewards constructedStakingRewards = new StakingRewards();

        // Expect revert when attempting to initialize the implementation contract.
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidInitialization.selector));
        constructedStakingRewards.initialize({ token_: address(1) });
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { Base_Test } from "test/Base.t.sol";
import { GoodRushERC20Mock } from "test/mocks/GoodRushERC20Mock.sol";
import { StakingRewards } from "src/StakingRewards.sol";

contract StakingRewards_Unit_Shared_Test is Base_Test {
    using Clones for address;

    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    GoodRushERC20Mock internal rushERC20Mock;
    StakingRewards internal stakingRewards;

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
        stakingRewards = StakingRewards(address(new StakingRewards()).clone());
        vm.label({ account: address(stakingRewards), newLabel: "StakingRewards" });
    }

    /// @dev Initializes the contract.
    function initialize() internal {
        rushERC20Mock.mint({ account: address(stakingRewards), amount: defaults.REWARDS_AMOUNT() });
        stakingRewards.initialize({ token_: address(rushERC20Mock) });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

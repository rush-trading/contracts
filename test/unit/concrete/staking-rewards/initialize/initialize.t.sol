// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { StakingRewards_Unit_Shared_Test } from "test/unit/shared/StakingRewards.t.sol";

contract Initialize_Unit_Concrete_Test is StakingRewards_Unit_Shared_Test {
    function test_RevertGiven_AlreadyInitialized() external {
        // Initialize the contract.
        stakingRewards.initialize({ token_: address(rushERC20Mock) });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidInitialization.selector));
        stakingRewards.initialize({ token_: address(rushERC20Mock) });
    }

    function test_GivenNotInitialized() external {
        // Mint some tokens to the contract as rewards.
        rushERC20Mock.mint({ account: address(stakingRewards), amount: defaults.RUSH_ERC20_SUPPLY() });

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(stakingRewards) });
        emit Initialize({ reward: defaults.RUSH_ERC20_SUPPLY() });

        // Initialize the contract.
        stakingRewards.initialize({ token_: address(rushERC20Mock) });

        // Assert that the contract was initialized correctly.
        address actualToken = address(stakingRewards.token());
        address expectedName = address(rushERC20Mock);
        assertEq(actualToken, expectedName, "token");

        uint256 actualRewardsDuration = stakingRewards.rewardsDuration();
        uint256 expectedRewardsDuration = 180 days;
        assertEq(actualRewardsDuration, expectedRewardsDuration, "rewardsDuration");

        uint256 actualRewardRate = stakingRewards.rewardRate();
        uint256 expectedRewardRate = defaults.RUSH_ERC20_SUPPLY() / stakingRewards.rewardsDuration();
        assertEq(actualRewardRate, expectedRewardRate, "rewardRate");

        uint256 actualLastUpdateTime = stakingRewards.lastUpdateTime();
        uint256 expectedLastUpdateTime = block.timestamp;
        assertEq(actualLastUpdateTime, expectedLastUpdateTime, "lastUpdateTime");

        uint256 actualPeriodFinish = stakingRewards.periodFinish();
        uint256 expectedPeriodFinish = block.timestamp + stakingRewards.rewardsDuration();
        assertEq(actualPeriodFinish, expectedPeriodFinish, "periodFinish");
    }
}

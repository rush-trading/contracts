// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Vm } from "forge-std/src/Vm.sol";
import { StakingRewards_Unit_Concrete_Test } from "test/unit/concrete/staking-rewards/StakingRewards.t.sol";

contract GetReward_Unit_Concrete_Test is StakingRewards_Unit_Concrete_Test {
    function setUp() public virtual override {
        StakingRewards_Unit_Concrete_Test.setUp();
        initialize();
        // Set Alice as the caller.
        resetPrank({ msgSender: users.alice });
    }

    function test_WhenRewardIsZero() external {
        // Do nothing.
        vm.recordLogs();
        stakingRewards.getReward();

        // Expect no events to be emitted.
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
    }

    function test_WhenRewardIsGreaterThanZero() external {
        // Stake tokens.
        uint256 amount = defaults.STAKING_AMOUNT();
        rushERC20Mock.mint({ account: users.alice, amount: amount });
        rushERC20Mock.approve({ spender: address(stakingRewards), value: amount });
        stakingRewards.stake({ amount: amount });

        // Fast forward 1 day.
        vm.warp(block.timestamp + 1 days);

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(stakingRewards) });
        uint256 reward = 5555.5555555555554e18;
        emit RewardPaid({ user: users.alice, reward: reward });

        // Get the reward.
        stakingRewards.getReward();

        // Assert the contract state.
        uint256 expectedReward = reward;
        uint256 actualReward = rushERC20Mock.balanceOf({ account: users.alice });
        assertEq(actualReward, expectedReward, "reward");
        assertEq(stakingRewards.rewards(users.alice), 0, "rewards");
    }
}

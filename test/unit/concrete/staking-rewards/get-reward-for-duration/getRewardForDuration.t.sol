// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { StakingRewards_Unit_Concrete_Test } from "test/unit/concrete/staking-rewards/StakingRewards.t.sol";

contract GetRewardForDuration_Unit_Concrete_Test is StakingRewards_Unit_Concrete_Test {
    function test_ShouldReturnCorrectRewardForDuration() external view {
        uint256 actualRewardForDuration = stakingRewards.getRewardForDuration();
        uint256 expectedRewardForDuration = stakingRewards.rewardRate() * stakingRewards.rewardsDuration();
        vm.assertEq(actualRewardForDuration, expectedRewardForDuration, "rewardForDuration");
    }
}

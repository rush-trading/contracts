// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { StakingRewards_Unit_Shared_Test } from "test/unit/shared/StakingRewards.t.sol";

contract lastTimeRewardApplicable_Unit_Fuzz_Test is StakingRewards_Unit_Shared_Test {
    function setUp() public virtual override {
        StakingRewards_Unit_Shared_Test.setUp();
        initialize();
    }

    function test_ShouldReturnCorrectLastTimeRewardApplicableValue(bool periodIsFinished) external {
        uint256 blockTimestamp;
        if (periodIsFinished) {
            blockTimestamp = bound(blockTimestamp, 0, stakingRewards.periodFinish() - 1);
        } else {
            blockTimestamp = bound(blockTimestamp, stakingRewards.periodFinish(), 2 * stakingRewards.periodFinish());
        }

        // Set the block timestamp.
        vm.warp(blockTimestamp);

        if (block.timestamp >= stakingRewards.periodFinish()) {
            // Assert that the value is correct.
            uint256 expected = stakingRewards.periodFinish();
            uint256 actual = stakingRewards.lastTimeRewardApplicable();
            assertEq(actual, expected, "lastTimeRewardApplicable");
        } else {
            // Assert that the value is correct.
            uint256 expected = block.timestamp;
            uint256 actual = stakingRewards.lastTimeRewardApplicable();
            assertEq(actual, expected, "lastTimeRewardApplicable");
        }
    }
}

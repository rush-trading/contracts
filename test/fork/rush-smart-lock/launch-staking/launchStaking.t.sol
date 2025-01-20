// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Errors } from "src/libraries/Errors.sol";
import { RushSmartLock_Test } from "../RushSmartLock.t.sol";

contract LaunchStaking_Fork_Test is RushSmartLock_Test {
    function test_RevertWhen_RushErc20IsZeroAddress() external {
        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.RushSmartLock_ZeroAddress.selector));
        rushSmartLock.launchStaking(address(0));
    }

    modifier whenRushErc20IsNotZeroAddress() {
        _;
    }

    function test_RevertWhen_RushErc20IsNotSuccessfulDeployment() external whenRushErc20IsNotZeroAddress {
        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.RushSmartLock_NotSuccessfulDeployment.selector, address(1)));
        rushSmartLock.launchStaking(address(1));
    }

    modifier whenRushErc20IsSuccessfulDeployment() {
        _;
    }

    function test_RevertWhen_StakingAlreadyLaunchedForRushErc20()
        external
        whenRushErc20IsNotZeroAddress
        whenRushErc20IsSuccessfulDeployment
    {
        // Launch staking for rushERC20
        (address rushERC20,) = launchSuccessfulRushERC20();
        rushSmartLock.launchStaking(rushERC20);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.RushSmartLock_StakingRewardsAlreadyLaunched.selector, rushERC20));
        rushSmartLock.launchStaking(rushERC20);
    }

    function test_WhenStakingNotYetLaunchedForRushErc20()
        external
        whenRushErc20IsNotZeroAddress
        whenRushErc20IsSuccessfulDeployment
    {
        // Launch successful rushERC20.
        (address rushERC20,) = launchSuccessfulRushERC20();

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(rushSmartLock) });
        emit LaunchStaking({ rushERC20: rushERC20 });

        // Launch staking for rushERC20.
        rushSmartLock.launchStaking(rushERC20);

        // Assert that the staking is launched.
        address stakingRewards = rushSmartLock.getStakingRewards(rushERC20);
        vm.assertTrue(stakingRewards != address(0), "stakingRewards");

        // Assert that the staking rewards contract has the total stake.
        uint256 rushERC20BalanceOfSmartLockAfter = IERC20(rushERC20).balanceOf(address(rushSmartLock));
        uint256 rushERC20BalanceOfStakingRewards = IERC20(rushERC20).balanceOf(stakingRewards);
        vm.assertEq(rushERC20BalanceOfSmartLockAfter, 0, "rushERC20BalanceOfSmartLock");
        vm.assertEq(rushERC20BalanceOfStakingRewards, defaults.STAKING_AMOUNT(), "rushERC20BalanceOfStakingRewards");
    }
}

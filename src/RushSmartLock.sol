// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import { ACLRoles } from "src/abstracts/ACLRoles.sol";
import { ILiquidityDeployer } from "src/interfaces/ILiquidityDeployer.sol";
import { IRushERC20 } from "src/interfaces/IRushERC20.sol";
import { IRushSmartLock } from "src/interfaces/IRushSmartLock.sol";
import { Errors } from "src/libraries/Errors.sol";
import { IRushERC20Factory } from "src/RushERC20Factory.sol";
import { RL } from "src/types/DataTypes.sol";

/**
 * @title RushSmartLock
 * @notice See the documentation in {IRushSmartLock}.
 */
contract RushSmartLock is IRushSmartLock, ACLRoles {
    /// @inheritdoc IRushSmartLock
    address public override liquidityDeployer;

    /// @inheritdoc IRushSmartLock
    address public override stakingRewardsImpl;

    constructor(address aclManager_, address liquidityDeployer_, address stakingRewardsImpl_) ACLRoles(aclManager_) {
        liquidityDeployer = liquidityDeployer_;
        stakingRewardsImpl = stakingRewardsImpl_;
    }

    /// @inheritdoc IRushSmartLock
    function launchStaking(address rushERC20) external {
        // TODO: Implement this function.

        // Emit an event.
        emit LaunchStaking(rushERC20);
    }

    /// @inheritdoc IRushSmartLock
    function setLiquidityDeployer(address newLiquidityDeployer) external {
        // Checks: `newLiquidityDeployer` must not be the zero address.
        if (newLiquidityDeployer == address(0)) {
            revert Errors.RushSmartLock__ZeroAddress();
        }

        // Effects: Set the new LiquidityDeployer address.
        liquidityDeployer = newLiquidityDeployer;

        // Emit an event.
        emit SetLiquidityDeployer(newLiquidityDeployer);
    }

    /// @inheritdoc IRushSmartLock
    function setStakingRewardsImpl(address newStakingRewardsImpl) external {
        // Checks: `newStakingRewardsImpl` must not be the zero address.
        if (newStakingRewardsImpl == address(0)) {
            revert Errors.RushSmartLock__ZeroAddress();
        }

        // Effects: Set the new StakingRewards implementation address.
        stakingRewardsImpl = newStakingRewardsImpl;

        // Emit an event.
        emit SetStakingRewardsImpl(newStakingRewardsImpl);
    }
}

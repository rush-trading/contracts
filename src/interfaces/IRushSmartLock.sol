// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import { IACLRoles } from "src/interfaces/IACLRoles.sol";

/**
 * @title IRushSmartLock
 * @notice Contains RushERC20 tokens after unwinding and launches staking rewards for successful unwinds.
 */
interface IRushSmartLock is IACLRoles {
    // #region ----------------------------=|+ NON-CONSTANT FUNCTIONS +|=---------------------------- //

    /**
     * @notice Launches the staking rewards contract for the RushERC20 token.
     *
     * Requirements:
     * - Given RushERC20 must be a successfully unwound token.
     *
     * @param rushERC20 The address of the RushERC20 token.
     */
    function launchStaking(address rushERC20) external;

    /**
     * @notice Set the address of the LiquidityDeployer contract.
     *
     * Requirements:
     * - Can only be called by the default admin role.
     * - New LiquidityDeployer address must not be the zero address.
     *
     * @param newLiquidityDeployer The address of the new LiquidityDeployer contract.
     */
    function setLiquidityDeployer(address newLiquidityDeployer) external;

    /**
     * @notice Set the address of the StakingRewards contract implementation.
     *
     * Requirements:
     * - Can only be called by the default admin role.
     * - The new implementation must support the required interface.
     *
     * @param newStakingRewardsImplementation The address of the new StakingRewards implementation.
     */
    function setStakingRewardsImplementation(address newStakingRewardsImplementation) external;

    // #endregion ----------------------------------------------------------------------------------- //
}

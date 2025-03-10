// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { ACLRoles } from "src/abstracts/ACLRoles.sol";
import { IUniswapV2Factory } from "src/external/IUniswapV2Factory.sol";
import { ILiquidityDeployer } from "src/interfaces/ILiquidityDeployer.sol";
import { ILiquidityPool } from "src/interfaces/ILiquidityPool.sol";
import { IRushERC20 } from "src/interfaces/IRushERC20.sol";
import { IRushSmartLock } from "src/interfaces/IRushSmartLock.sol";
import { IStakingRewards } from "src/interfaces/IStakingRewards.sol";
import { Errors } from "src/libraries/Errors.sol";
import { LD } from "src/types/DataTypes.sol";

/**
 * @title RushSmartLock
 * @notice See the documentation in {IRushSmartLock}.
 */
contract RushSmartLock is IRushSmartLock, ACLRoles {
    using Clones for address;

    // #region ----------------------------------=|+ IMMUTABLES +|=---------------------------------- //

    /// @inheritdoc IRushSmartLock
    address public immutable override UNISWAP_V2_FACTORY;

    /// @inheritdoc IRushSmartLock
    address public immutable override WETH;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ PUBLIC STORAGE +|=-------------------------------- //

    /// @inheritdoc IRushSmartLock
    mapping(address rushERC20 => address stakingRewards) public override getStakingRewards;

    /// @inheritdoc IRushSmartLock
    address public override liquidityDeployer;

    /// @inheritdoc IRushSmartLock
    address public override stakingRewardsImpl;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    /**
     * @dev Constructor
     * @param aclManager_ The address of the ACLManager contract.
     * @param liquidityPool_ The address of the LiquidityPool contract.
     * @param uniswapV2Factory_ The address of the Uniswap V2 factory contract.
     */
    constructor(address aclManager_, address liquidityPool_, address uniswapV2Factory_) ACLRoles(aclManager_) {
        UNISWAP_V2_FACTORY = uniswapV2Factory_;
        WETH = ILiquidityPool(liquidityPool_).asset();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------=|+ PERMISSIONED NON-CONSTANT FUNCTIONS +|=---------------------- //

    /// @inheritdoc IRushSmartLock
    function setLiquidityDeployer(address newLiquidityDeployer) external onlyAdminRole {
        // Checks: `newLiquidityDeployer` must not be the zero address.
        if (newLiquidityDeployer == address(0)) {
            revert Errors.RushSmartLock_ZeroAddress();
        }

        // Effects: Set the new LiquidityDeployer address.
        liquidityDeployer = newLiquidityDeployer;

        // Emit an event.
        emit SetLiquidityDeployer(newLiquidityDeployer);
    }

    /// @inheritdoc IRushSmartLock
    function setStakingRewardsImpl(address newStakingRewardsImpl) external onlyAdminRole {
        // Checks: `newStakingRewardsImpl` must not be the zero address.
        if (newStakingRewardsImpl == address(0)) {
            revert Errors.RushSmartLock_ZeroAddress();
        }

        // Effects: Set the new StakingRewards implementation address.
        stakingRewardsImpl = newStakingRewardsImpl;

        // Emit an event.
        emit SetStakingRewardsImpl(newStakingRewardsImpl);
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------=|+ USER-FACING NON-CONSTANT FUNCTIONS +|=---------------------- //

    /// @inheritdoc IRushSmartLock
    function launchStaking(address rushERC20) external {
        // Checks: `stakingRewardsImpl` must not be the zero address.
        if (stakingRewardsImpl == address(0)) {
            revert Errors.RushSmartLock_StakingRewardsImplNotSet();
        }
        // Checks: `rushERC20` must not be the zero address.
        if (rushERC20 == address(0)) {
            revert Errors.RushSmartLock_ZeroAddress();
        }

        // Get the UniV2 pair address.
        address uniV2Pair = IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair({ tokenA: rushERC20, tokenB: WETH });

        // Get the liquidity deployment data.
        LD.LiquidityDeployment memory liquidityDeployment =
            ILiquidityDeployer(liquidityDeployer).getLiquidityDeployment({ uniV2Pair: uniV2Pair });

        // Checks: `rushERC20` must be a successful deployment.
        if (!liquidityDeployment.isUnwindThresholdMet) {
            revert Errors.RushSmartLock_NotSuccessfulDeployment(rushERC20);
        }

        // Checks: Staking rewards must not already be launched for the given RushERC20 token.
        if (getStakingRewards[rushERC20] != address(0)) {
            revert Errors.RushSmartLock_StakingRewardsAlreadyLaunched(rushERC20);
        }

        // Effects: Clone the staking rewards implementation contract.
        address stakingRewards = stakingRewardsImpl.clone();

        // Effects: Set the staking rewards contract address.
        getStakingRewards[rushERC20] = stakingRewards;

        // Interactions: Transfer total RushERC20 balance to the staking rewards contract.
        IRushERC20(rushERC20).transfer({ to: stakingRewards, value: IRushERC20(rushERC20).balanceOf(address(this)) });

        // Interactions: Initialize the staking rewards contract.
        IStakingRewards(stakingRewards).initialize(rushERC20);

        // Emit an event.
        emit LaunchStaking(rushERC20);
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

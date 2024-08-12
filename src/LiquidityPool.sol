// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import { ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC4626, IERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { ACLRoles } from "src/abstracts/ACLRoles.sol";
import { ILiquidityPool } from "src/interfaces/ILiquidityPool.sol";
import { Errors } from "src/libraries/Errors.sol";

/**
 * @title LiquidityPool
 * @notice See the documentation in {ILiquidityPool}.
 */
contract LiquidityPool is ILiquidityPool, ERC4626, ACLRoles {
    // #region --------------------------------=|+ PUBLIC STORAGE +|=-------------------------------- //

    /// @inheritdoc ILiquidityPool
    uint256 public override maxTotalDeposits;

    /// @inheritdoc ILiquidityPool
    uint256 public override outstandingAssets;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    /**
     * @dev Constructor
     * @param aclManager_ The address of the ACLManager contract.
     * @param asset_ The address of the base asset.
     * @param maxTotalDeposits_ The maximum total deposits allowed in the pool.
     */
    constructor(
        address aclManager_,
        address asset_,
        uint256 maxTotalDeposits_
    )
        ACLRoles(aclManager_)
        ERC4626(ERC20(asset_))
        ERC20(
            string(abi.encodePacked("Rush ", ERC20(asset_).name(), " Liquidity Pool")),
            string(abi.encodePacked("r", ERC20(asset_).symbol()))
        )
    {
        maxTotalDeposits = maxTotalDeposits_;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /// @dev See {IERC4626-totalAssets}.
    function totalAssets() public view override(ERC4626, IERC4626) returns (uint256) {
        return IERC20(asset()).balanceOf(address(this)) + outstandingAssets;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------=|+ PERMISSIONED NON-CONSTANT FUNCTIONS +|=---------------------- //

    /// @inheritdoc ILiquidityPool
    function dispatchAsset(address to, uint256 amount) external override onlyAssetManagerRole {
        // Checks: `to` must not be the zero address.
        if (to == address(0)) {
            revert Errors.LiquidityPool_ZeroAddress();
        }
        // Checks: `to` must not be the contract address.
        if (to == address(this)) {
            revert Errors.LiquidityPool_SelfDispatch();
        }
        // Checks: `amount` must be greater than zero.
        if (amount == 0) {
            revert Errors.LiquidityPool_ZeroAmount();
        }

        // Effects: Increase the total amount of outstanding assets.
        outstandingAssets += amount;

        // Interactions: Transfer the asset to the recipient.
        IERC20(asset()).transfer(to, amount);

        // Emit an event.
        emit DispatchAsset({ originator: msg.sender, to: to, amount: amount });
    }

    /// @inheritdoc ILiquidityPool
    function returnAsset(address from, uint256 amount) external override onlyAssetManagerRole {
        // Checks: `from` must not be the zero address.
        if (from == address(0)) {
            revert Errors.LiquidityPool_ZeroAddress();
        }
        // Checks: `from` must not be the contract address.
        if (from == address(this)) {
            revert Errors.LiquidityPool_SelfReturn();
        }
        // Checks: `amount` must be greater than zero.
        if (amount == 0) {
            revert Errors.LiquidityPool_ZeroAmount();
        }

        // Effects: Decrease the total amount of outstanding assets.
        outstandingAssets -= amount;

        // Interactions: Transfer the asset from the sender.
        IERC20(asset()).transferFrom(from, address(this), amount);

        // Emit an event.
        emit ReturnAsset({ originator: msg.sender, from: from, amount: amount });
    }

    /// @inheritdoc ILiquidityPool
    function setMaxTotalDeposits(uint256 newMaxTotalDeposits) external override onlyAdminRole {
        // Checks: `newMaxTotalDeposits` must be greater than zero.
        if (newMaxTotalDeposits == 0) {
            revert Errors.LiquidityPool_ZeroAmount();
        }

        // Effects: Set the maximum total deposits allowed in the pool.
        maxTotalDeposits = newMaxTotalDeposits;

        // Emit an event.
        emit SetMaxTotalDeposits({ newMaxTotalDeposits: newMaxTotalDeposits });
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------=|+ USER-FACING NON-CONSTANT FUNCTIONS +|=---------------------- //

    function deposit(uint256 assets, address receiver) public override(ERC4626, IERC4626) returns (uint256) {
        // Checks: total deposits must not exceed the maximum limit.
        if (assets + totalAssets() > maxTotalDeposits) {
            revert Errors.LiquidityPool_MaxTotalDepositsExceeded();
        }

        return super.deposit(assets, receiver);
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

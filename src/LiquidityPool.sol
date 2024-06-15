// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IDispatchAssetCallback } from "src/interfaces/callback/IDispatchAssetCallback.sol";
import { IReturnAssetCallback } from "src/interfaces/callback/IReturnAssetCallback.sol";
import { Errors } from "src/libraries/Errors.sol";

/**
 * @title LiquidityPool
 * @notice A permissioned ERC4626-based liquidity pool contract.
 */
contract LiquidityPool is ERC4626, AccessControl {
    // #region ------------------------------------=|+ EVENTS +|=------------------------------------ //

    /**
     * @notice Emitted when assets are dispatched.
     * @param originator The originator of the request.
     * @param to The address to which assets were dispatched.
     * @param amount The amount of assets dispatched.
     */
    event DispatchAsset(address indexed originator, address indexed to, uint256 amount);

    /**
     * @notice Emitted when assets are returned.
     * @param originator The originator of the request.
     * @param from The address from which assets were returned.
     * @param amount The amount of assets returned.
     */
    event ReturnAsset(address indexed originator, address indexed from, uint256 amount);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ ROLE CONSTANTS +|=-------------------------------- //

    /// @notice The asset manager role.
    bytes32 public constant ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ PUBLIC STORAGE +|=-------------------------------- //

    /// @notice The total amount of outstanding assets.
    uint256 public outstandingAssets;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    /**
     * Constructor
     * @param admin_ The address to grant the admin role.
     * @param assetManager_ The address to grant the asset manager role.
     * @param weth_ The address of the WETH token.
     */
    constructor(
        address admin_,
        address assetManager_,
        address weth_
    )
        ERC4626(ERC20(weth_))
        // TODO: rename to be more inline with branding
        ERC20("Wrapped Ether Vault", "vWETH")
    {
        _grantRole({ role: DEFAULT_ADMIN_ROLE, account: admin_ });
        _grantRole({ role: ASSET_MANAGER_ROLE, account: assetManager_ });
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /// @dev See {IERC4626-totalAssets}.
    function totalAssets() public view override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this)) + outstandingAssets;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------=|+ PERMISSIONED NON-CONSTANT FUNCTIONS +|=---------------------- //

    /**
     * @notice Dispatches assets to a recipient.
     *
     * Requirements:
     * - The caller must have the `ASSET_MANAGER_ROLE`.
     * - The `to` address must not be the zero address.
     * - The `amount` must be greater than zero.
     *
     * Actions:
     * - Increases the total amount of outstanding assets.
     * - Transfers the asset from the contract to the recipient.
     * - Executes the callback logic after transferring the assets.
     *
     * @param to The address to which assets are dispatched.
     * @param amount The amount of assets to dispatch.
     * @param data Additional data.
     */
    function dispatchAsset(address to, uint256 amount, bytes calldata data) public onlyRole(ASSET_MANAGER_ROLE) {
        // Checks: `to` must not be the zero address.
        if (to == address(0)) {
            revert Errors.LiquidityPool_ZeroAddress();
        }
        // Checks: `amount` must be greater than zero.
        if (amount == 0) {
            revert Errors.LiquidityPool_ZeroAmount();
        }

        // Effects: Increase the total amount of outstanding assets.
        outstandingAssets += amount;

        // Interactions: Transfer the asset to the recipient.
        IERC20(asset()).transfer(to, amount);
        // Interactions: Execute the callback logic after transferring the assets.
        IDispatchAssetCallback(msg.sender).onDispatchAsset({ to: to, amount: amount, data: data });

        // Emit an event.
        emit DispatchAsset({ originator: msg.sender, to: to, amount: amount });
    }

    /**
     * @notice Returns assets from a sender.
     *
     * Requirements:
     * - The caller must have the `ASSET_MANAGER_ROLE`.
     * - The `from` address must not be the zero address.
     * - The `amount` must be greater than zero.
     *
     * Actions:
     * - Decreases the total amount of outstanding assets.
     * - Executes the callback logic before receiving the assets.
     * - Transfers the asset from the sender to the contract.
     *
     * @param from The address from which assets are returned.
     * @param amount The amount of assets to return.
     * @param data Additional data.
     */
    function returnAsset(address from, uint256 amount, bytes calldata data) public onlyRole(ASSET_MANAGER_ROLE) {
        // Checks: `from` must not be the zero address.
        if (from == address(0)) {
            revert Errors.LiquidityPool_ZeroAddress();
        }
        // Checks: `amount` must be greater than zero.
        if (amount == 0) {
            revert Errors.LiquidityPool_ZeroAmount();
        }

        // Effects: Decrease the total amount of outstanding assets.
        outstandingAssets -= amount;

        // Interactions: Execute the callback logic before receiving the assets.
        IReturnAssetCallback(msg.sender).onReturnAsset({ from: from, amount: amount, data: data });
        // Interactions: Transfer the asset from the sender.
        IERC20(asset()).transferFrom(from, address(this), amount);

        // Emit an event.
        emit ReturnAsset({ originator: msg.sender, from: from, amount: amount });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

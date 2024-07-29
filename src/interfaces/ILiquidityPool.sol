// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { IERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IACLRoles } from "src/interfaces/IACLRoles.sol";

/**
 * @title ILiquidityPool
 * @notice A permissioned ERC4626-based liquidity pool contract.
 */
interface ILiquidityPool is IERC4626, IACLRoles {
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

    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /// @notice The total amount of outstanding assets.
    function outstandingAssets() external view returns (uint256);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------=|+ NON-CONSTANT FUNCTIONS +|=---------------------------- //

    /**
     * @notice Dispatches assets to a recipient.
     *
     * Requirements:
     * - The caller must have the asset manager role.
     * - The caller must implement the IDispatchAssetCallback interface.
     * - The `to` address must not be the zero address.
     * - The `to` address must not be the contract address itself.
     * - The asset amount must be greater than zero.
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
    function dispatchAsset(address to, uint256 amount, bytes calldata data) external;

    /**
     * @notice Returns assets from a sender.
     *
     * Requirements:
     * - The caller must have the asset manager role.
     * - The caller must implement the IReturnAssetCallback interface.
     * - The `from` address must not be the zero address.
     * - The `from` address must not be the contract address itself.
     * - The asset amount must be greater than zero.
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
    function returnAsset(address from, uint256 amount, bytes calldata data) external;

    // #endregion ----------------------------------------------------------------------------------- //
}

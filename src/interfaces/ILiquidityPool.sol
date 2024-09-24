// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

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

    /**
     * @notice Emitted when the maximum total deposits allowed in the pool is updated.
     * @param newMaxTotalDeposits The new maximum total deposits allowed in the pool.
     */
    event SetMaxTotalDeposits(uint256 newMaxTotalDeposits);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /// @notice The latest snapshot of the total assets managed by the pool.
    function lastSnapshotTotalAssets() external view returns (uint256);

    /// @notice The maximum total deposits allowed in the pool.
    function maxTotalDeposits() external view returns (uint256);

    /// @notice The total amount of outstanding assets.
    function outstandingAssets() external view returns (uint256);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------=|+ NON-CONSTANT FUNCTIONS +|=---------------------------- //

    /**
     * @notice Dispatches assets to a recipient.
     *
     * Requirements:
     * - The caller must have the asset manager role.
     * - The `to` address must not be the zero address.
     * - The `to` address must not be the contract address itself.
     * - The asset amount must be greater than zero.
     *
     * Actions:
     * - Increases the total amount of outstanding assets.
     * - Transfers the asset from the contract to the recipient.
     *
     * @param to The address to which assets are dispatched.
     * @param amount The amount of assets to dispatch.
     */
    function dispatchAsset(address to, uint256 amount) external;

    /**
     * @notice Returns assets from a sender.
     *
     * Requirements:
     * - The caller must have the asset manager role.
     * - The `from` address must not be the zero address.
     * - The `from` address must not be the contract address itself.
     * - The asset amount must be greater than zero.
     *
     * Actions:
     * - Decreases the total amount of outstanding assets.
     * - Transfers the asset from the sender to the contract.
     *
     * @param from The address from which assets are returned.
     * @param amount The amount of assets to return.
     */
    function returnAsset(address from, uint256 amount) external;

    /**
     * @notice Sets the maximum total deposits allowed in the pool.
     *
     * Requirements:
     * - The caller must have the admin role.
     * - The new maximum total deposits must be greater than zero.
     *
     * @param newMaxTotalDeposits The new maximum total deposits allowed in the pool.
     */
    function setMaxTotalDeposits(uint256 newMaxTotalDeposits) external;

    /**
     * @notice Takes a snapshot of the total assets managed by the pool.
     *
     * Requirements:
     * - The caller must have the admin role.
     */
    function takeSnapshotTotalAssets() external;

    // #endregion ----------------------------------------------------------------------------------- //
}

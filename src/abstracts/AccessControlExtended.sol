// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title AccessControlExtended
 * @notice An extended version of AccessControl with additional roles.
 */
abstract contract AccessControlExtended is AccessControl {
    // #region --------------------------------=|+ ROLE CONSTANTS +|=-------------------------------- //

    /// @notice The liquidity deployer role.
    bytes32 internal constant LIQUIDITY_DEPLOYER_ROLE = keccak256("LIQUIDITY_DEPLOYER_ROLE");

    /// @notice The reserve manager role.
    bytes32 internal constant RESERVE_MANAGER_ROLE = keccak256("RESERVE_MANAGER_ROLE");

    /// @notice The token deployer role.
    bytes32 internal constant TOKEN_DEPLOYER_ROLE = keccak256("TOKEN_DEPLOYER_ROLE");

    // #endregion ----------------------------------------------------------------------------------- //
}

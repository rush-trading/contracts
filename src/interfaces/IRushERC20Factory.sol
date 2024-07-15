// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { IAccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { CloneTemplate } from "src/libraries/CloneTemplate.sol";

/**
 * @title IRushERC20Factory
 * @notice A permissioned factory for deploying ERC20 tokens using predefined templates.
 */
interface IRushERC20Factory is IAccessControl {
    // #region ------------------------------------=|+ EVENTS +|=------------------------------------ //

    /**
     * @dev Emitted when a new token template is added.
     * @param kind The kind of token template.
     * @param version The version of the token implementation.
     * @param implementation The address of the token implementation.
     */
    event AddTemplate(bytes32 indexed kind, uint256 indexed version, address implementation);

    /**
     * @dev Emitted when a new RushERC20 token contract is created.
     * @param originator The address of the originator of creation request.
     * @param kind The kind of token.
     * @param version The version of the token implementation.
     * @param rushERC20 The address of the new RushERC20 token.
     */
    event CreateRushERC20(address indexed originator, bytes32 indexed kind, uint256 indexed version, address rushERC20);

    /**
     * @dev Emitted when a token template is removed.
     * @param kind The kind of token template.
     * @param version The version of the token implementation.
     */
    event RemoveTemplate(bytes32 indexed kind, uint256 indexed version);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /// @notice The liquidity deployer role.
    function LIQUIDITY_DEPLOYER_ROLE() external view returns (bytes32);

    /// @notice The rush creator role.
    function RUSH_CREATOR_ROLE() external view returns (bytes32);

    /// @notice Retrieves the template entity.
    function getTemplate(bytes32 kind) external view returns (CloneTemplate.Data memory template);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------=|+ NON-CONSTANT FUNCTIONS +|=---------------------------- //

    /**
     * @notice Add a new token template.
     * @dev It's not an error to rewrite an existing template with the same kind.
     *
     * Requirements:
     * - The caller must have the default admin role.
     * - The token implementation must support the required interface.
     *
     * Actions:
     * - Adds given token template to the factory.
     *
     * @param implementation The address of the token implementation.
     */
    function addTemplate(address implementation) external;

    /**
     * @notice Creates a new RushERC20 token of a given kind.
     * @dev Created tokens are not initialized.
     *
     * Requirements:
     * - The caller must have the rush creator role.
     * - A token implementation must be registered for the given kind.
     *
     * Actions:
     * - Creates a new ERC20 token with given kind.
     *
     * @param kind The kind of token to create.
     * @param originator The address of the originator of creation request.
     * @return rushERC20 The address of the new RushERC20 token.
     */
    function createRushERC20(bytes32 kind, address originator) external returns (address rushERC20);

    /**
     * @notice Remove a token template.
     *
     * Requirements:
     * - The caller must have the default admin role.
     * - The given kind must be registered in the factory.
     *
     * Actions:
     * - Remove token template from the factory.
     *
     * @param kind The kind of token template to remove.
     */
    function removeTemplate(bytes32 kind) external;

    // #endregion ----------------------------------------------------------------------------------- //
}

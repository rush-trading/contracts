// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { AccessControlExtended } from "src/abstracts/AccessControlExtended.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IRushERC20 } from "src/interfaces/IRushERC20.sol";
import { CloneTemplate } from "src/libraries/CloneTemplate.sol";

/**
 * @title RushERC20Factory
 * @notice A permissioned factory for deploying ERC20 tokens using predefined templates.
 */
contract RushERC20Factory is AccessControlExtended {
    using Address for address;
    using CloneTemplate for CloneTemplate.Data;

    // #region --------------------------------=|+ CUSTOM ERRORS +|=--------------------------------- //

    /// @dev Emitted when the implementation does not support the required interface.
    error RushERC20Factory_InvalidInterfaceId();

    /**
     * @dev Emitted when the template does not exist.
     * @param kind The kind of token template.
     */
    error RushERC20Factory_NotTemplate(bytes32 kind);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------------=|+ EVENTS +|=------------------------------------ //

    /**
     * @dev Emitted when a new token template is added.
     * @param kind The kind of token template.
     * @param version The version of the token implementation.
     * @param implementation The address of the token implementation.
     */
    event AddTemplate(bytes32 indexed kind, uint256 indexed version, address implementation);

    /**
     * @dev Emitted when a new token contract is created.
     * @param originator The address of the originator of creation request.
     * @param kind The kind of token.
     * @param version The version of the token implementation.
     * @param token The address of the created token.
     */
    event CreateERC20(address indexed originator, bytes32 indexed kind, uint256 indexed version, address token);

    /**
     * @dev Emitted when a token template is removed.
     * @param kind The kind of token template.
     * @param version The version of the token implementation.
     */
    event RemoveTemplate(bytes32 indexed kind, uint256 indexed version);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ PUBLIC STORAGE +|=-------------------------------- //

    /// @notice A mapping of token templates.
    mapping(bytes32 kind => CloneTemplate.Data template) public templates;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    /**
     * @dev Constructor
     *
     * @param admin_ The address to grant the admin role.
     */
    constructor(address admin_) {
        _grantRole({ role: DEFAULT_ADMIN_ROLE, account: admin_ });
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------=|+ PERMISSIONED NON-CONSTANT FUNCTIONS +|=---------------------- //

    /**
     * @notice Add a new token template.
     * @dev It's not an error to rewrite an existing template with the same kind.
     *
     * Requirements:
     * - The caller must have the default admin role.
     * - The implementation must support the required interface.
     *
     * Actions:
     * - Adds given token template to the factory.
     *
     * @param implementation The address of the token implementation.
     */
    function addTemplate(address implementation) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Checks: Implementation must support the required interface.
        if (!IERC165(implementation).supportsInterface(type(IRushERC20).interfaceId)) {
            revert RushERC20Factory_InvalidInterfaceId();
        }

        // Effects: Add token template to the factory.
        // TODO: check possible collisions with keccak256, possibly via fuzzing.
        bytes32 kind = keccak256(abi.encodePacked(IRushERC20(implementation).description()));
        templates[kind].set({ implementation: implementation });

        // Emit an event.
        emit AddTemplate({ kind: kind, version: IRushERC20(implementation).version(), implementation: implementation });
    }

    /**
     * @notice Creates a new ERC20 token of a given kind.
     * @dev Created tokens are not initialized.
     *
     * Requirements:
     * - The caller must have the token deployer role.
     * - An implementation must be registered for the given kind.
     *
     * Actions:
     * - Creates a new ERC20 token with given kind.
     *
     * @param kind The kind of token to create.
     * @param originator The address of the originator of creation request.
     */
    function createERC20(
        bytes32 kind,
        address originator
    )
        external
        onlyRole(TOKEN_DEPLOYER_ROLE)
        returns (address token)
    {
        // Effects: Create a new token using the implementation.
        token = templates[kind].clone();

        // Emit an event.
        emit CreateERC20({ originator: originator, kind: kind, version: IRushERC20(token).version(), token: token });
    }

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
    function removeTemplate(bytes32 kind) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Checks: The given kind must be registered in the factory.
        address implementation = templates[kind].implementation;
        if (implementation == address(0)) {
            revert RushERC20Factory_NotTemplate(kind);
        }

        // Effects: Remove token template from the factory.
        delete templates[kind];

        // Emit an event.
        emit RemoveTemplate({ kind: kind, version: IRushERC20(implementation).version() });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

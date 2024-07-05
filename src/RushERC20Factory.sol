// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IRushERC20Factory } from "src/interfaces/IRushERC20Factory.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IRushERC20 } from "src/interfaces/IRushERC20.sol";
import { CloneTemplate } from "src/libraries/CloneTemplate.sol";
import { Errors } from "src/libraries/Errors.sol";

/**
 * @title RushERC20Factory
 * @notice See the documentation in {IRushERC20Factory}.
 */
contract RushERC20Factory is IRushERC20Factory, AccessControl {
    using Address for address;
    using CloneTemplate for CloneTemplate.Data;

    // #region --------------------------------=|+ ROLE CONSTANTS +|=-------------------------------- //

    /// @notice The liquidity deployer role.
    bytes32 public constant override LIQUIDITY_DEPLOYER_ROLE = keccak256("LIQUIDITY_DEPLOYER_ROLE");

    /// @notice The rush creator role.
    bytes32 public constant override RUSH_CREATOR_ROLE = keccak256("RUSH_CREATOR_ROLE");

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -------------------------------=|+ INTERNAL STORAGE +|=------------------------------- //

    /// @dev A mapping of token templates.
    mapping(bytes32 kind => CloneTemplate.Data template) internal _templates;

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

    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /// @inheritdoc IRushERC20Factory
    function getTemplate(bytes32 kind) external view override returns (CloneTemplate.Data memory template) {
        return _templates[kind];
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------=|+ PERMISSIONED NON-CONSTANT FUNCTIONS +|=---------------------- //

    /// @inheritdoc IRushERC20Factory
    function addTemplate(address implementation) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Checks: Implementation must support the required interface.
        if (!IERC165(implementation).supportsInterface(type(IRushERC20).interfaceId)) {
            revert Errors.RushERC20Factory_InvalidInterfaceId();
        }

        // Effects: Add token template to the factory.
        bytes32 kind = keccak256(abi.encodePacked(IRushERC20(implementation).description()));
        _templates[kind].set({ implementation: implementation });

        // Emit an event.
        emit AddTemplate({ kind: kind, version: IRushERC20(implementation).version(), implementation: implementation });
    }

    /// @inheritdoc IRushERC20Factory
    function createRushERC20(
        bytes32 kind,
        address originator
    )
        external
        onlyRole(RUSH_CREATOR_ROLE)
        returns (address rushERC20)
    {
        // Effects: Create a new token using the implementation.
        rushERC20 = _templates[kind].clone();

        // Emit an event.
        emit CreateRushERC20({
            originator: originator,
            kind: kind,
            version: IRushERC20(rushERC20).version(),
            rushERC20: rushERC20
        });
    }

    /// @inheritdoc IRushERC20Factory
    function removeTemplate(bytes32 kind) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Checks: The given kind must be registered in the factory.
        address implementation = _templates[kind].implementation;
        if (implementation == address(0)) {
            revert Errors.RushERC20Factory_NotTemplate(kind);
        }

        // Effects: Remove token template from the factory.
        delete _templates[kind];

        // Emit an event.
        emit RemoveTemplate({ kind: kind, version: IRushERC20(implementation).version() });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

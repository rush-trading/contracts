// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ACLRoles } from "src/abstracts/ACLRoles.sol";
import { IRushERC20 } from "src/interfaces/IRushERC20.sol";
import { IRushERC20Factory } from "src/interfaces/IRushERC20Factory.sol";
import { Errors } from "src/libraries/Errors.sol";

/**
 * @title RushERC20Factory
 * @notice See the documentation in {IRushERC20Factory}.
 */
contract RushERC20Factory is IRushERC20Factory, ACLRoles {
    using Clones for address;

    // #region -------------------------------=|+ INTERNAL STORAGE +|=------------------------------- //

    /// @dev A mapping of token templates.
    mapping(bytes32 kind => address template) internal _templates;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    /**
     * @dev Constructor
     * @param aclManager_ The address of the ACLManager contract.
     */
    constructor(address aclManager_) ACLRoles(aclManager_) { }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /// @inheritdoc IRushERC20Factory
    function getTemplate(bytes32 kind) external view override returns (address template) {
        return _templates[kind];
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------=|+ PERMISSIONED NON-CONSTANT FUNCTIONS +|=---------------------- //

    /// @inheritdoc IRushERC20Factory
    function addTemplate(address implementation) external onlyAdminRole {
        // Checks: Implementation must support the required interface.
        if (!IERC165(implementation).supportsInterface(type(IRushERC20).interfaceId)) {
            revert Errors.RushERC20Factory_InvalidInterfaceId();
        }

        // Effects: Add token template.
        bytes32 kind = keccak256(abi.encodePacked(IRushERC20(implementation).description()));
        _templates[kind] = implementation;

        // Emit an event.
        emit AddTemplate({ kind: kind, version: IRushERC20(implementation).version(), implementation: implementation });
    }

    /// @inheritdoc IRushERC20Factory
    function createRushERC20(bytes32 kind, address originator) external onlyLauncherRole returns (address rushERC20) {
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
    function removeTemplate(string calldata description) external onlyAdminRole {
        // Checks: The given kind must be registered.
        bytes32 kind = keccak256(abi.encodePacked(description));
        address implementation = _templates[kind];
        if (implementation == address(0)) {
            revert Errors.RushERC20Factory_NotTemplate(kind);
        }

        // Effects: Remove token template.
        delete _templates[kind];

        // Emit an event.
        emit RemoveTemplate({ kind: kind, version: IRushERC20(implementation).version() });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

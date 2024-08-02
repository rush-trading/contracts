// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title CloneTemplate
 * @notice A library for creating EIP-1167 clones from a template.
 */
library CloneTemplate {
    using Clones for address;

    // #region -----------------------------------=|+ STRUCTS +|=------------------------------------ //

    /**
     * @dev The clone template data.
     * @param implementation The address of the clone implementation.
     */
    struct Data {
        address implementation;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------=|+ NON-CONSTANT FUNCTIONS +|=---------------------------- //

    /**
     * @dev Creates an EIP-1167 clone from the template.
     * @param self The clone template data.
     * @return The address of the new clone instance.
     */
    function clone(Data storage self) internal returns (address) {
        return self.implementation.clone();
    }

    /**
     * @dev Sets the clone template data.
     * @param self The clone template data.
     * @param implementation The address of the clone implementation.
     */
    function set(Data storage self, address implementation) internal {
        self.implementation = implementation;
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

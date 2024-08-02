// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import { ERC165, IERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IRushERC20 } from "src/interfaces/IRushERC20.sol";

/**
 * @title RushERC20Abstract
 * @notice The abstract Rush ERC20 token contract.
 */
abstract contract RushERC20Abstract is Initializable, IRushERC20, ERC165 {
    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    constructor() {
        // Prevent the token implementation contract from being initialized.
        _disableInitializers();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IRushERC20).interfaceId || super.supportsInterface(interfaceId);
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

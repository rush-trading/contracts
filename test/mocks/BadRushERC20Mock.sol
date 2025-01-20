// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ERC165, IERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { IRushERC20 } from "src/interfaces/IRushERC20.sol";

/**
 * @title BadRushERC20Mock
 */
contract BadRushERC20Mock is ERC165, ERC20Upgradeable, IRushERC20 {
    /// @inheritdoc IRushERC20
    function description() public pure returns (string memory) {
        return "RushERC20Mock";
    }

    /// @inheritdoc IRushERC20
    function initialize(
        string calldata,
        string calldata,
        uint256,
        address,
        bytes calldata
    )
        public
        override
        initializer
    { }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IRushERC20
    function version() public pure returns (uint256) {
        return 42;
    }
}

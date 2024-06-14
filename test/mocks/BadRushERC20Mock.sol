// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
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

    /// @inheritdoc IRushERC20
    function version() public pure returns (uint256) {
        return 42;
    }
}

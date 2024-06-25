// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { IRushERC20, RushERC20Abstract } from "src/abstracts/RushERC20Abstract.sol";

/**
 * @title GoodRushERC20Mock
 */
contract GoodRushERC20Mock is RushERC20Abstract, ERC20Upgradeable {
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

    /// @inheritdoc RushERC20Abstract
    function supportsInterface(bytes4 interfaceId) public view override(RushERC20Abstract) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IRushERC20
    function version() public pure override returns (uint256) {
        return 42;
    }

    /// @dev Mints tokens to the specified account.
    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}

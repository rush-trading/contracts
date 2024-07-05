// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { IRushERC20, RushERC20Abstract } from "src/abstracts/RushERC20Abstract.sol";

/**
 * @title GoodRushERC20Mock
 */
contract GoodRushERC20Mock is RushERC20Abstract, ERC20Upgradeable {
    string private _descriptionOverride;
    uint256 private _versionOverride;

    /// @inheritdoc IRushERC20
    function description() public view override returns (string memory) {
        return bytes(_descriptionOverride).length > 0 ? _descriptionOverride : "RushERC20Mock";
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
    function version() public view override returns (uint256) {
        return (_versionOverride) > 0 ? _versionOverride : 42;
    }

    /// @dev Mints tokens to the specified account.
    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    /// @dev Updates the description of the token implementation.
    function setDescription(string calldata newDescription) public {
        _descriptionOverride = newDescription;
    }

    /// @dev Updates the version of the token implementation.
    function setVersion(uint256 newVersion) public {
        _versionOverride = newVersion;
    }
}

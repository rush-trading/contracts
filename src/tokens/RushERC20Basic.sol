// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { IRushERC20, RushERC20Abstract } from "src/abstracts/RushERC20Abstract.sol";

/**
 * @title RushERC20Basic
 * @notice The basic ERC20 token implementation for rush.trading.
 */
contract RushERC20Basic is ERC20Upgradeable, RushERC20Abstract {
    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /// @inheritdoc IRushERC20
    function description() public pure override returns (string memory) {
        return "RushERC20Basic";
    }

    /// @inheritdoc IRushERC20
    function version() public pure override returns (uint256) {
        return 0;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------=|+ NON-CONSTANT FUNCTIONS +|=---------------------------- //

    /// @inheritdoc IRushERC20
    function initialize(
        string calldata name,
        string calldata symbol,
        uint256 maxSupply,
        address recipient,
        bytes calldata
    )
        public
        override
        initializer
    {
        __ERC20_init(name, symbol);
        _mint(recipient, maxSupply);
        emit Initialize(name, symbol, maxSupply, recipient, "");
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

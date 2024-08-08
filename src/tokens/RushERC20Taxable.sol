// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { IRushERC20, RushERC20Abstract } from "src/abstracts/RushERC20Abstract.sol";
import {StaticTaxHandler} from "src/abstracts/StaticTaxHandler.sol";

/**
 * @title RushERC20Basic
 * @notice The basic Rush ERC20 token implementation.
 */
contract RushERC20Taxable is ERC20Upgradeable, RushERC20Abstract, StaticTaxHandler {
    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /// @inheritdoc IRushERC20
    function description() public pure override returns (string memory) {
        return "RushERC20Taxable";
    }

    /// @inheritdoc IRushERC20
    function version() public pure override returns (uint256) {
        return 1;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------=|+ NON-CONSTANT FUNCTIONS +|=---------------------------- //

    /// @inheritdoc IRushERC20
    function initialize(
        string calldata name,
        string calldata symbol,
        uint256 maxSupply,
        address recipient,
        bytes calldata data
    )
        public
        override
        initializer
    {
        // Don't like the fact that owner is passed in calldata, it should be propogated via msg.sender...
        __ERC20_init(name, symbol);
        _mint(recipient, maxSupply);
        __StaticTaxHandler_init(data);

        emit Initialize({ name: name, symbol: symbol, maxSupply: maxSupply, recipient: recipient, data: data });
    }

        /**
     * @dev Overrides update function to tax into account the Tax
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal override {
        // require(value > 0, "Transfer amount must be greater than zero.");
        uint256 tax = getTax(from,to,value);
        uint256 taxedAmount = value - tax;
        super._update(from,to, taxedAmount);
        if (tax > 0) {
            super._update(from, taxBeneficiary, tax);
        }
    }


    // #endregion ----------------------------------------------------------------------------------- //
}

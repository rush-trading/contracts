// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import { ERC20TaxableUpgradeable } from "src/abstracts/ERC20TaxableUpgradeable.sol";
import { IRushERC20, RushERC20Abstract } from "src/abstracts/RushERC20Abstract.sol";

/**
 * @title RushERC20Taxable
 * @notice The taxable Rush ERC20 token implementation.
 */
contract RushERC20Taxable is ERC20TaxableUpgradeable, RushERC20Abstract {
    // #region -----------------------------------=|+ STRUCTS +|=------------------------------------ //

    struct InitializeLocalVars {
        address initialOwner;
        address initialExemption;
        uint256 initialTaxBasisPoints;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /// @inheritdoc IRushERC20
    function description() external pure override returns (string memory) {
        return "RushERC20Taxable";
    }

    /// @inheritdoc IRushERC20
    function version() external pure override returns (uint256) {
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
        external
        override
        initializer
    {
        InitializeLocalVars memory vars;
        __ERC20_init(name, symbol);
        _mint(recipient, maxSupply);
        (vars.initialOwner, vars.initialExemption, vars.initialTaxBasisPoints) =
            abi.decode(data, (address, address, uint256));
        __ERC20Taxable_init({
            initialOwner: vars.initialOwner,
            initialExchangePool: recipient,
            initialExemption: vars.initialExemption,
            initialTaxBasisPoints: vars.initialTaxBasisPoints
        });
        emit Initialize({ name: name, symbol: symbol, maxSupply: maxSupply, recipient: recipient, data: data });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

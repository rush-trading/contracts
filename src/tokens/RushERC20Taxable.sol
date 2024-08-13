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
        address owner;
        address exchangePool;
        uint256 initialTaxBasisPoints;
        address liquidityDeployer;
        address router;
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
        // TODO: Don't like the fact that owner is passed in calldata, it should be propogated via msg.sender...
        (vars.owner, vars.initialTaxBasisPoints, vars.liquidityDeployer, vars.router) = abi.decode(data, (address, uint256, address,address));
        __ERC20Taxable_init(vars.owner, recipient, vars.initialTaxBasisPoints,vars.liquidityDeployer, vars.router);
        emit Initialize({ name: name, symbol: symbol, maxSupply: maxSupply, recipient: recipient, data: data });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

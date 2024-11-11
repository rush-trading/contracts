// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import { ERC20DonatableUpgradeable } from "src/abstracts/ERC20DonatableUpgradeable.sol";
import { IRushERC20, RushERC20Abstract } from "src/abstracts/RushERC20Abstract.sol";

/**
 * @title RushERC20Donatable
 * @notice The donatable Rush ERC20 token implementation.
 */
contract RushERC20Donatable is ERC20DonatableUpgradeable, RushERC20Abstract {
    // #region -----------------------------------=|+ STRUCTS +|=------------------------------------ //

    struct InitializeLocalVars {
        address donationBeneficiary;
        address liquidityDeployer;
        address uniV2Pair;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /// @inheritdoc IRushERC20
    function description() external pure override returns (string memory) {
        return "RushERC20Donatable";
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
        (vars.donationBeneficiary, vars.liquidityDeployer) = abi.decode(data, (address, address));
        __ERC20Donatable_init({
            _donationBeneficiary: vars.donationBeneficiary,
            _liquidityDeployer: vars.liquidityDeployer,
            _uniV2Pair: recipient
        });
        emit Initialize({ name: name, symbol: symbol, maxSupply: maxSupply, recipient: recipient, data: data });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

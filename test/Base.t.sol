// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Test } from "forge-std/src/Test.sol";
import { Users } from "./utils/Types.sol";
import { Utils } from "./utils/Utils.sol";
import { Constants } from "./utils/Constants.sol";
import { Defaults } from "./utils/Defaults.sol";
import { Events } from "./utils/Events.sol";

import { DefaultFeeCalculator } from "src/fee-calculator/strategies/DefaultFeeCalculator.sol";
import { RushERC20Factory } from "src/RushERC20Factory.sol";

/// @notice Base test contract with common logic needed by all tests.
abstract contract Base_Test is Test, Utils, Constants, Events {
    // #region ----------------------------------=|+ VARIABLES +|=----------------------------------- //

    Users internal users;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    Defaults internal defaults;
    // TODO: Use interfaces instead of concrete contracts.
    DefaultFeeCalculator internal feeCalculator;
    RushERC20Factory internal rushERC20Factory;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ SET-UP FUNCTION +|=------------------------------- //

    function setUp() public virtual {
        // Create users for testing.
        users = Users({
            admin: createUser("Admin"),
            assetManager: createUser("AssetManager"),
            eve: createUser("Eve"),
            liquidityDeployer: createUser("LiquidityDeployer"),
            sender: createUser("Sender"),
            tokenDeployer: createUser("TokenDeployer")
        });

        // Deploy the defaults contract.
        defaults = new Defaults();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Generates a user, labels its address, and funds it with test assets.
    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        return user;
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

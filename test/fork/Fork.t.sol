// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { IUniswapV2Factory } from "src/external/IUniswapV2Factory.sol";
import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all fork tests.
abstract contract Fork_Test is Base_Test {
    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    IUniswapV2Factory internal constant uniswapV2Factory = IUniswapV2Factory(0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -------------------------------=|+ SET-UP FUNCTION +|=-------------------------------- //

    function setUp() public virtual override {
        // Fork Base at a specific block number.
        vm.createSelectFork({ blockNumber: 15_870_000, urlOrAlias: "base" });

        Base_Test.setUp();

        // Deploy the contracts.
        deployCore();

        // Grant roles.
        grantRolesCore();

        // Approve the contracts.
        approveCore();
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Factory } from "src/external/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "src/external/IUniswapV2Router02.sol";
import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all fork tests.
abstract contract Fork_Test is Base_Test {
    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    IUniswapV2Factory internal constant uniswapV2Factory = IUniswapV2Factory(0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6);
    IERC20 internal constant weth = IERC20(0x4200000000000000000000000000000000000006);
    IUniswapV2Router02 internal constant uniswapRouter02 =
        IUniswapV2Router02(0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24);
    // #endregion ----------------------------------------------------------------------------------- //

    // #region -------------------------------=|+ SET-UP FUNCTION +|=-------------------------------- //

    function setUp() public virtual override {
        // Fork Base at a specific block number.
        vm.createSelectFork({ blockNumber: 15_870_000, urlOrAlias: "base" });

        Base_Test.setUp();

        // Deploy the core contracts.
        deployCore({ asset: address(weth) });

        // Grant roles.
        grantRolesCore();
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

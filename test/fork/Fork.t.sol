// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { RushERC20Factory } from "src/RushERC20Factory.sol";
import { IUniswapV2Factory } from "src/external/IUniswapV2Factory.sol";
import { GoodRushERC20Mock } from "test/mocks/GoodRushERC20Mock.sol";
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

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Creates a RushERC20 token.
    function createRushERC20() internal returns (address) {
        (, address caller,) = vm.readCallers();
        changePrank({ msgSender: users.admin });
        address implementation = address(new GoodRushERC20Mock());
        rushERC20Factory.addTemplate({ implementation: implementation });
        changePrank({ msgSender: users.tokenDeployer });
        address erc20 = rushERC20Factory.createERC20({ originator: users.sender, kind: defaults.TEMPLATE_KIND() });
        changePrank({ msgSender: caller });
        return erc20;
    }

    /// @dev Deposits assets from the Sender to the liquidity pool.
    function depositToLiquidityPool(uint256 amount) internal {
        (, address caller,) = vm.readCallers();
        changePrank({ msgSender: users.sender });
        liquidityPool.deposit({ assets: amount, receiver: users.sender });
        changePrank({ msgSender: caller });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

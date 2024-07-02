// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { RushLauncher } from "src/RushLauncher.sol";

import { Fork_Test } from "../Fork.t.sol";

contract RushLauncher_Test is Fork_Test {
    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    RushLauncher internal rushLauncher;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ SET-UP FUNCTION +|=------------------------------- //

    function setUp() public virtual override {
        Fork_Test.setUp();
        deploy();
        grantRoles();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Deploys the contract.
    function deploy() internal {
        rushLauncher = new RushLauncher({
            baseAsset_: address(weth),
            erc20Factory_: rushERC20Factory,
            liquidityDeployer_: address(liquidityDeployer),
            maxSupplyLimit_: defaults.RUSH_ERC20_MAX_SUPPLY(),
            minSupplyLimit_: defaults.RUSH_ERC20_MIN_SUPPLY(),
            uniswapV2Factory_: address(uniswapV2Factory)
        });
        vm.label({ account: address(rushLauncher), newLabel: "RushLauncher" });
    }

    /// @dev Grants roles.
    function grantRoles() internal {
        (, address caller,) = vm.readCallers();
        resetPrank({ msgSender: users.admin });
        rushERC20Factory.grantRole({ role: RUSH_CREATOR_ROLE, account: address(rushLauncher) });
        liquidityDeployer.grantRole({ role: LIQUIDITY_DEPLOYER_ROLE, account: address(rushLauncher) });
        resetPrank({ msgSender: caller });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

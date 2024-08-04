// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

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
            liquidityDeployer_: address(liquidityDeployer),
            maxSupplyLimit_: defaults.MAX_RUSH_ERC20_SUPPLY(),
            minSupplyLimit_: defaults.MIN_RUSH_ERC20_SUPPLY(),
            rushERC20Factory_: address(rushERC20Factory),
            uniswapV2Factory_: address(uniswapV2Factory)
        });
        vm.label({ account: address(rushLauncher), newLabel: "RushLauncher" });
    }

    /// @dev Grants roles.
    function grantRoles() internal {
        (, address caller,) = vm.readCallers();
        resetPrank({ msgSender: users.admin });
        aclManager.addLauncher({ account: address(rushLauncher) });
        resetPrank({ msgSender: caller });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

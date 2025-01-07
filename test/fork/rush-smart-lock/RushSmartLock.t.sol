// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { RushSmartLock } from "src/RushSmartLock.sol";
import { StakingRewards } from "src/StakingRewards.sol";
import { Fork_Test } from "../Fork.t.sol";

contract RushSmartLock_Test is Fork_Test {
    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    RushSmartLock internal rushSmartLock;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ SET-UP FUNCTION +|=------------------------------- //

    function setUp() public virtual override {
        Fork_Test.setUp();
        deploy();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Deploys the contract.
    function deploy() internal {
        rushSmartLock = new RushSmartLock({
            aclManager_: address(aclManager),
            liquidityPool_: address(liquidityPool),
            stakingRewardsImpl_: address(new StakingRewards()),
            uniswapV2Factory_: address(uniswapV2Factory)
        });
        vm.label({ account: address(rushSmartLock), newLabel: "RushSmartLock" });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

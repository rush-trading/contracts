// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { LiquidityDeployerWETH_Fork_Test } from "../LiquidityDeployerWETH.t.sol";

contract OnDispatchAsset_Fork_Test is LiquidityDeployerWETH_Fork_Test {
    function test_RevertGiven_CallerIsNotLiquidityPool() external {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        uint256 amount = defaults.DISPATCH_AMOUNT();
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_InvalidCallbackSender.selector, users.eve));
        liquidityDeployerWETH.onDispatchAsset(users.eve, amount, "");
    }
}

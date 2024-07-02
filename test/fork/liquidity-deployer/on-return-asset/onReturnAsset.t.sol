// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { LiquidityDeployer_Fork_Test } from "../LiquidityDeployer.t.sol";

contract OnReturnAsset_Fork_Test is LiquidityDeployer_Fork_Test {
    function test_RevertGiven_CallerIsNotLiquidityPool() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        uint256 amount = defaults.DISPATCH_AMOUNT();
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_InvalidCallbackSender.selector, users.eve));
        liquidityDeployer.onReturnAsset(users.eve, amount, "");
    }
}

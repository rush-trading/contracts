// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { LiquidityDeployerWETH_Fork_Test } from "../LiquidityDeployerWETH.t.sol";

contract Unpause_Fork_Test is LiquidityDeployerWETH_Fork_Test {
    function test_RevertWhen_CallerDoesNotHaveAdminRole() external {
        // Set Eve as the caller.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.AccessControlUnauthorizedAccount.selector, users.eve, DEFAULT_ADMIN_ROLE)
        );
        liquidityDeployerWETH.unpause();
    }

    function test_WhenCallerHasAdminRole() external {
        // Set Admin as the caller.
        changePrank({ msgSender: users.admin });

        // Pause the contract.
        liquidityDeployerWETH.pause();

        // Unpause the contract.
        liquidityDeployerWETH.unpause();
    }
}

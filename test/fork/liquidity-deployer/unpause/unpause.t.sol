// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { LiquidityDeployer_Fork_Test } from "../LiquidityDeployer.t.sol";

contract Unpause_Fork_Test is LiquidityDeployer_Fork_Test {
    function test_RevertWhen_CallerDoesNotHaveAdminRole() external {
        // Set Eve as the caller.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.OnlyAdminRole.selector, users.eve));
        liquidityDeployer.unpause();
    }

    function test_WhenCallerHasAdminRole() external {
        // Set Admin as the caller.
        resetPrank({ msgSender: users.admin });

        // Pause the contract.
        pause();

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(liquidityDeployer) });
        emit Unpause();

        // Unpause the contract.
        liquidityDeployer.unpause();
    }
}

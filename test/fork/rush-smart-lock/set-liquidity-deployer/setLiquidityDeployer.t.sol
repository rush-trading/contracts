// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { RushSmartLock_Test } from "../RushSmartLock.t.sol";

contract SetLiquidityDeployer_Fork_Test is RushSmartLock_Test {
    function test_RevertWhen_CallerDoesNotHaveAdminRole() external {
        // Set Eve as the caller.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.OnlyAdminRole.selector, users.eve));
        rushSmartLock.setLiquidityDeployer(address(0));
    }

    modifier whenCallerHasAdminRole() {
        resetPrank({ msgSender: users.admin });
        _;
    }

    function test_RevertWhen_NewLiquidityDeployerIsZeroAddress() external whenCallerHasAdminRole {
        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.RushSmartLock_ZeroAddress.selector));
        rushSmartLock.setLiquidityDeployer(address(0));
    }

    function test_WhenNewLiquidityDeployerIsNotZeroAddress() external whenCallerHasAdminRole {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(rushSmartLock) });
        emit SetLiquidityDeployer({ newLiquidityDeployer: address(1) });

        // Set the new liquidity deployer.
        rushSmartLock.setLiquidityDeployer(address(1));

        // Assert that the new fee calculator is set.
        address actualLiquidtyDeployer = rushSmartLock.liquidityDeployer();
        address expectedLiquidtyDeployer = address(1);
        vm.assertEq(actualLiquidtyDeployer, expectedLiquidtyDeployer, "liquidityDeployer");
    }
}

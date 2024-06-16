// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { LiquidityPool } from "src/LiquidityPool.sol";

import { Base_Test } from "test/Base.t.sol";

contract LiquidityPool_Integration_Concrete_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
        deploy();

        // Cache the caller.
        (, address caller,) = vm.readCallers();
        // Make Admin the caller in this test.
        changePrank({ msgSender: users.admin });
        // Grant the asset manager role to the DispatchAssetCaller.
        liquidityPool.grantRole({ role: ASSET_MANAGER_ROLE, account: address(dispatchAssetCaller) });
        // Grant the asset manager role to the ReturnAssetCaller.
        liquidityPool.grantRole({ role: ASSET_MANAGER_ROLE, account: address(returnAssetCaller) });
        // Restore caller.
        changePrank({ msgSender: caller });

        approveLiquidityPool();
    }

    /// @dev Approves liquidity pool to spend assets from the Sender.
    function approveLiquidityPool() internal {
        // Cache the caller.
        (, address caller,) = vm.readCallers();

        // Make Sender the caller in this test.
        changePrank({ msgSender: users.sender });

        // Approve the pool to spend WETH.
        weth.approve({ spender: address(liquidityPool), value: type(uint256).max });

        // Restore caller.
        changePrank({ msgSender: caller });
    }

    function deploy() internal {
        liquidityPool = new LiquidityPool({ admin_: users.admin, weth_: address(weth) });
        vm.label({ account: address(liquidityPool), newLabel: "LiquidityPool" });
    }

    function depositToLiquidityPool(uint256 amount) internal {
        // Cache the caller.
        (, address caller,) = vm.readCallers();

        // Make Sender the caller in this test.
        changePrank({ msgSender: users.sender });

        // Add deposits to the pool.
        liquidityPool.deposit({ assets: amount, receiver: users.sender });

        // Restore caller.
        changePrank({ msgSender: caller });
    }

    function dispatchFromLiquidityPool(uint256 amount) internal {
        // Cache the caller.
        (, address caller,) = vm.readCallers();

        // Make DispatchAssetCaller the caller in this test.
        changePrank({ msgSender: address(dispatchAssetCaller) });

        // Dispatch the asset.
        liquidityPool.dispatchAsset({ to: users.recipient, amount: amount, data: "" });

        // Restore caller.
        changePrank({ msgSender: caller });
    }
}

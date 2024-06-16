// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { LiquidityPool } from "src/LiquidityPool.sol";

import { Base_Test } from "test/Base.t.sol";

contract LiquidityPool_Integration_Concrete_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
        deploy();
        grantRoles();
        approveLiquidityPool();
    }

    /// @dev Approves liquidity pool to spend assets from the Sender.
    function approveLiquidityPool() internal {
        (, address caller,) = vm.readCallers();
        changePrank({ msgSender: users.sender });
        weth.approve({ spender: address(liquidityPool), value: type(uint256).max });
        changePrank({ msgSender: caller });
    }

    /// @dev Deploys the contract.
    function deploy() internal {
        liquidityPool = new LiquidityPool({ admin_: users.admin, weth_: address(weth) });
        vm.label({ account: address(liquidityPool), newLabel: "LiquidityPool" });
    }

    /// @dev Deposits assets from the Sender to the liquidity pool.
    function depositToLiquidityPool(uint256 amount) internal {
        (, address caller,) = vm.readCallers();
        changePrank({ msgSender: users.sender });
        liquidityPool.deposit({ assets: amount, receiver: users.sender });
        changePrank({ msgSender: caller });
    }

    /// @dev Dispatches assets from the liquidity pool to the Recipient.
    function dispatchFromLiquidityPool(uint256 amount) internal {
        (, address caller,) = vm.readCallers();
        changePrank({ msgSender: address(dispatchAssetCaller) });
        liquidityPool.dispatchAsset({ to: users.recipient, amount: amount, data: "" });
        changePrank({ msgSender: caller });
    }

    /// @dev grants liquidity pool roles.
    function grantRoles() internal {
        (, address caller,) = vm.readCallers();
        changePrank({ msgSender: users.admin });
        liquidityPool.grantRole({ role: ASSET_MANAGER_ROLE, account: address(dispatchAssetCaller) });
        liquidityPool.grantRole({ role: ASSET_MANAGER_ROLE, account: address(returnAssetCaller) });
        changePrank({ msgSender: caller });
    }
}

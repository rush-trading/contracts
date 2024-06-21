// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { LiquidityPool } from "src/LiquidityPool.sol";

import { Integration_Test } from "test/integration/Integration.t.sol";

contract LiquidityPool_Integration_Concrete_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();
    }

    /// @dev Dispatches assets from the liquidity pool to the Recipient.
    function dispatchFromLiquidityPool(uint256 amount) internal {
        (, address caller,) = vm.readCallers();
        changePrank({ msgSender: address(dispatchAssetCaller) });
        liquidityPool.dispatchAsset({ to: users.recipient, amount: amount, data: "" });
        changePrank({ msgSender: caller });
    }
}

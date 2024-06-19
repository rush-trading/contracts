// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Fork_Test } from "test/fork/Fork.t.sol";

contract LiquidityDeployerWETH_Fork_Test is Fork_Test {
    address internal pair;
    address internal token;

    function setUp() public virtual override {
        Fork_Test.setUp();
        deploy();

        depositToLiquidityPool({ amount: defaults.DEPOSIT_AMOUNT() });
    }

    /// @dev Deploys the contracts.
    function deploy() internal {
        token = createRushERC20();
        vm.label({ account: token, newLabel: "RushERC20" });
        pair = uniswapV2Factory.createPair({ tokenA: token, tokenB: address(weth) });
        vm.label({ account: pair, newLabel: "UniswapV2Pair" });
    }
}

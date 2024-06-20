// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Fork_Test } from "test/fork/Fork.t.sol";
import { GoodRushERC20Mock } from "test/mocks/GoodRushERC20Mock.sol";

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

    /// @dev Deploys liquidity to the pair.
    function deployLiquidityToPair(
        address originator_,
        address pair_,
        address token_,
        uint256 tokenAmount_,
        uint256 wethAmount_,
        uint256 duration_,
        uint256 feeAmount_
    )
        internal
    {
        (, address caller,) = vm.readCallers();
        changePrank({ msgSender: address(users.liquidityDeployer) });
        GoodRushERC20Mock(token).mint({ account: pair_, amount: tokenAmount_ });
        liquidityDeployerWETH.deployLiquidity{ value: feeAmount_ }({
            originator: originator_,
            pair: pair_,
            token: token_,
            amount: wethAmount_,
            duration: duration_
        });
        changePrank({ msgSender: caller });
    }

    /// @dev Unwinds the liquidity from the pair.
    function unwindLiquidityFromPair(address pair_, uint256 timestamp_) internal {
        (, address caller,) = vm.readCallers();
        changePrank({ msgSender: address(users.liquidityDeployer) });
        vm.warp(timestamp_);
        liquidityDeployerWETH.unwindLiquidity({ pair: pair_ });
        changePrank({ msgSender: caller });
    }
}

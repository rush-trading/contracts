// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { IRushERC20Taxable } from "src/interfaces/IRushERC20Taxable.sol";
import { Fork_Test } from "test/fork/Fork.t.sol";
import "forge-std/src/console.sol";
import { RushERC20Taxable } from "src/tokens/RushERC20Taxable.sol";
import { IUniswapV2Pair } from "src/external/IUniswapV2Pair.sol";

contract UniswapTrade is Fork_Test {
    address exchangePool;

    function setUp() public virtual override {
        Fork_Test.setUp();
        deploy();
    }

    function deploy() internal {
        address implementation = address(new RushERC20Taxable());

        addTemplate({ implementation: implementation });
        rushERC20 = IRushERC20Taxable(createRushERC20({ implementation: implementation }));
        vm.label({ account: address(rushERC20), newLabel: "RushERC20Taxable" });

        resetPrank({ msgSender: users.sender });

        bytes memory initData = abi.encode(users.sender, address(0), defaults.ERC20_TAXABLE_RATE_BPS());
        rushERC20.initialize("TestTaxToken", "TTT", defaults.RUSH_ERC20_SUPPLY(), users.sender, initData);
        exchangePool = uniswapV2Factory.createPair(address(rushERC20), address(weth));
        address(weth).call{ value: 100 ether }("");
        IRushERC20Taxable(address(rushERC20)).addExchangePool(exchangePool);
        IRushERC20Taxable(address(rushERC20)).removeExemption(users.sender);
        console.log(rushERC20.balanceOf(users.sender));
        // approvals
        resetPrank({ msgSender: users.sender });
        weth.approve(exchangePool, type(uint256).max);
        rushERC20.approve(exchangePool, type(uint256).max);
        weth.approve(address(uniswapRouter02), type(uint256).max);
        rushERC20.approve(address(uniswapRouter02), type(uint256).max);

        uniswapRouter02.addLiquidity(
            address(rushERC20),
            address(weth),
            rushERC20.balanceOf(users.sender) / 2,
            10 ether,
            0,
            0,
            users.sender,
            block.timestamp + 100
        );
    }

    function testFuzz_SwapExactETHForTokens(uint256 ethAmount) public {
        uint256 startingTaxTokenBalance = rushERC20.balanceOf(users.sender);
        vm.assume(ethAmount < address(users.sender).balance);
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(exchangePool).getReserves();
        uint256 reserveIn;
        uint256 reserveOut;
        reserveIn = uint256(reserve1);
        reserveOut = uint256(reserve0);

        if (IUniswapV2Pair(exchangePool).token0() == address(weth)) {
            reserveIn = uint256(reserve0);
            reserveOut = uint256(reserve1);
        }

        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(rushERC20);

        uint256 nonTaxTokenAmountOut = uniswapRouter02.getAmountOut(0.5 ether, reserveIn, reserveOut);
        uniswapRouter02.swapExactETHForTokens{ value: 0.5 ether }(
            nonTaxTokenAmountOut, path, users.sender, block.timestamp + 100
        );

        uint256 expectedTax = (IRushERC20Taxable(address(rushERC20)).taxBasisPoints() * nonTaxTokenAmountOut) / 10_000;
        uint256 endingTaxTokenbalance = rushERC20.balanceOf(users.sender);
        assertEq(startingTaxTokenBalance + nonTaxTokenAmountOut, endingTaxTokenbalance + expectedTax);
    }

    /*
        Should revert since the pool gets less tokens that it expects due to the tax
        violating the K constraint.
    */
    function testFuzz_RevertWhen_vanillaUniV2Sell() public {
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(exchangePool).getReserves();
        uint256 reserveIn;
        uint256 reserveOut;
        reserveOut = uint256(reserve1);
        reserveIn = uint256(reserve0);

        if (IUniswapV2Pair(exchangePool).token0() == address(weth)) {
            reserveOut = uint256(reserve0);
            reserveIn = uint256(reserve1);
        }

        address[] memory path = new address[](2);
        path[1] = address(weth);
        path[0] = address(rushERC20);
        uint256 requiredAmountIn = uniswapRouter02.getAmountIn(0.5 ether, reserveIn, reserveOut);
        vm.expectRevert();
        uniswapRouter02.swapTokensForExactETH(0.5 ether, requiredAmountIn, path, users.sender, block.timestamp + 100);
    }

    // Fee specific swap, should fail because we don't factor in the tax in request
    function test_revertWhenIgnoreTax_swapExactTokensForETHSupportingFeeOnTransferTokens() public {
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(exchangePool).getReserves();
        uint256 reserveIn;
        uint256 reserveOut;
        reserveOut = uint256(reserve1);
        reserveIn = uint256(reserve0);

        if (IUniswapV2Pair(exchangePool).token0() == address(weth)) {
            reserveOut = uint256(reserve1);
            reserveIn = uint256(reserve0);
        }

        address[] memory path = new address[](2);
        path[1] = address(weth);
        path[0] = address(rushERC20);
        uint256 requiredAmountIn = uniswapRouter02.getAmountIn(0.5 ether, reserveIn, reserveOut);
        vm.expectRevert();
        uniswapRouter02.swapExactTokensForETHSupportingFeeOnTransferTokens(
            requiredAmountIn, 0.5 ether, path, users.sender, block.timestamp + 100
        );
    }

    // Should pass because we factor the tax in
    function test_swapExactTokensForETHSupportingFeeOnTransferTokens() public {
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(exchangePool).getReserves();
        uint256 reserveIn;
        uint256 reserveOut;
        reserveOut = uint256(reserve1);
        reserveIn = uint256(reserve0);

        if (IUniswapV2Pair(exchangePool).token0() == address(weth)) {
            reserveOut = uint256(reserve1);
            reserveIn = uint256(reserve0);
        }

        address[] memory path = new address[](2);
        path[1] = address(weth);
        path[0] = address(rushERC20);
        uint256 desiredAmountIn = uniswapRouter02.getAmountIn(0.5 ether, reserveIn, reserveOut);
        uint256 actualAmountIn =
            desiredAmountIn - (desiredAmountIn * IRushERC20Taxable(address(rushERC20)).taxBasisPoints()) / 10_000;
        uint256 ethAmountOut = uniswapRouter02.getAmountOut(actualAmountIn, reserveOut, reserveIn);
        uniswapRouter02.swapExactTokensForETHSupportingFeeOnTransferTokens(
            desiredAmountIn, ethAmountOut, path, users.sender, block.timestamp + 100
        );
    }
}

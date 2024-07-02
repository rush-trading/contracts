// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { IUniswapV2Pair } from "src/external/IUniswapV2Pair.sol";
import { Fork_Test } from "test/fork/Fork.t.sol";
import { GoodRushERC20Mock } from "test/mocks/GoodRushERC20Mock.sol";

contract LiquidityDeployer_Fork_Test is Fork_Test {
    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    address internal uniV2Pair;
    address internal rushERC20Mock;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ SET-UP FUNCTION +|=------------------------------- //

    function setUp() public virtual override {
        Fork_Test.setUp();
        deploy();
        deposit({ asset: address(weth), amount: defaults.DEPOSIT_AMOUNT() });
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Deploys the contracts.
    function deploy() internal {
        rushERC20Mock = createRushERC20({ implementation: address(new GoodRushERC20Mock()) });
        vm.label({ account: rushERC20Mock, newLabel: "RushERC20Mock" });
        uniV2Pair = uniswapV2Factory.createPair({ tokenA: rushERC20Mock, tokenB: address(weth) });
        vm.label({ account: uniV2Pair, newLabel: "UniswapV2Pair" });
    }

    /// @dev Deploys liquidity to the Uniswap V2 pair.
    function deployLiquidity(
        address originator_,
        address uniV2Pair_,
        address rushERC20_,
        uint256 rushERC20Amount_,
        uint256 wethAmount_,
        uint256 duration_,
        uint256 feeAmount_
    )
        internal
    {
        (, address caller,) = vm.readCallers();
        resetPrank({ msgSender: address(users.liquidityDeployer) });
        GoodRushERC20Mock(rushERC20Mock).mint({ account: uniV2Pair_, amount: rushERC20Amount_ });
        liquidityDeployer.deployLiquidity{ value: feeAmount_ }({
            originator: originator_,
            uniV2Pair: uniV2Pair_,
            rushERC20: rushERC20_,
            amount: wethAmount_,
            duration: duration_
        });
        IUniswapV2Pair(uniV2Pair_).sync();
        resetPrank({ msgSender: caller });
    }

    /// @dev Pauses the contract.
    function pause() internal {
        (, address caller,) = vm.readCallers();
        resetPrank({ msgSender: address(users.admin) });
        liquidityDeployer.pause();
        resetPrank({ msgSender: caller });
    }

    /// @dev Unwinds the liquidity from the Uniswap V2 pair.
    function unwindLiquidity(address uniV2Pair_) internal {
        (, address caller,) = vm.readCallers();
        resetPrank({ msgSender: address(users.liquidityDeployer) });
        liquidityDeployer.unwindLiquidity({ uniV2Pair: uniV2Pair_ });
        resetPrank({ msgSender: caller });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { IUniswapV2Pair } from "src/external/IUniswapV2Pair.sol";
import { FC } from "src/types/DataTypes.sol";
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
        resetPrank({ msgSender: users.launcher });
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

    /// @dev Gets the fee amount needed to deploy liquidity.
    function getDeployLiquidityFee(uint256 amount, uint256 duration) internal view returns (uint256 feeAmount) {
        (feeAmount,) = feeCalculator.calculateFee(
            FC.CalculateFeeParams({
                duration: duration,
                newLiquidity: amount,
                outstandingLiquidity: liquidityPool.outstandingAssets(),
                reserveFactor: liquidityDeployer.RESERVE_FACTOR(),
                totalLiquidity: liquidityPool.totalAssets()
            })
        );
    }

    /// @dev Pauses the contract.
    function pause() internal {
        (, address caller,) = vm.readCallers();
        resetPrank({ msgSender: users.admin });
        liquidityDeployer.pause();
        resetPrank({ msgSender: caller });
    }

    /// @dev Unwinds the liquidity from the Uniswap V2 pair.
    function unwindLiquidity(address uniV2Pair_) internal {
        (, address caller,) = vm.readCallers();
        (bool success, bytes memory data) = address(liquidityDeployer).call(abi.encodeWithSignature("paused()"));
        assert(success);
        bool isPaused = abi.decode(data, (bool));
        if (isPaused) {
            resetPrank({ msgSender: users.admin });
            liquidityDeployer.unpause();
        }
        resetPrank({ msgSender: users.launcher });
        liquidityDeployer.unwindLiquidity({ uniV2Pair: uniV2Pair_ });
        if (isPaused) {
            resetPrank({ msgSender: users.admin });
            liquidityDeployer.pause();
        }
        resetPrank({ msgSender: caller });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

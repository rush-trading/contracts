// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { IUniswapV2Pair } from "src/external/IUniswapV2Pair.sol";
import { IRushERC20 } from "src/interfaces/IRushERC20.sol";
import { RushSmartLock } from "src/RushSmartLock.sol";
import { StakingRewards } from "src/StakingRewards.sol";
import { RushERC20Basic } from "src/tokens/RushERC20Basic.sol";
import { FC, RL } from "src/types/DataTypes.sol";
import { RushLauncher_Test } from "../rush-launcher/RushLauncher.t.sol";

contract RushSmartLock_Test is RushLauncher_Test {
    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    IRushERC20 internal rushERC20Template;
    RushSmartLock internal rushSmartLock;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ SET-UP FUNCTION +|=------------------------------- //

    function setUp() public virtual override {
        RushLauncher_Test.setUp();

        // Deploy the contract.
        rushSmartLock = new RushSmartLock({
            aclManager_: address(aclManager),
            liquidityPool_: address(liquidityPool),
            stakingRewardsImpl_: address(new StakingRewards()),
            uniswapV2Factory_: address(uniswapV2Factory)
        });
        setLiquidityDeployer();
        vm.label({ account: address(rushSmartLock), newLabel: "RushSmartLock" });

        // Deposit liquidity to LiquidityPool.
        deposit({ asset: address(weth), amount: defaults.DEPOSIT_AMOUNT() });

        // Add template to RushERC20Factory.
        rushERC20Template = new RushERC20Basic();
        addTemplate({ implementation: address(rushERC20Template) });
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Launches a successful RushERC20 deployment.
    function launchSuccessfulRushERC20() internal returns (address rushERC20, address uniV2Pair) {
        (, address caller,) = vm.readCallers();
        resetPrank({ msgSender: users.router });
        uint256 maxSupply = defaults.MAX_RUSH_ERC20_SUPPLY();
        uint256 liquidityAmount = defaults.LIQUIDITY_AMOUNT();
        uint256 liquidityDuration = defaults.LIQUIDITY_DURATION();
        bytes32 kind = keccak256(abi.encodePacked(rushERC20Template.description()));
        (uint256 fee,) = feeCalculator.calculateFee(
            FC.CalculateFeeParams({
                duration: liquidityDuration,
                newLiquidity: liquidityAmount,
                outstandingLiquidity: liquidityPool.outstandingAssets(),
                reserveFactor: defaults.RESERVE_FACTOR(),
                totalLiquidity: liquidityPool.lastSnapshotTotalAssets()
            })
        );
        (rushERC20, uniV2Pair) = rushLauncher.launch{ value: fee }(
            RL.LaunchParams({
                originator: users.eve,
                kind: kind,
                name: "MyToken",
                symbol: "MTK",
                maxSupply: maxSupply,
                data: abi.encodePacked(users.recipient, ""),
                liquidityAmount: liquidityAmount,
                liquidityDuration: liquidityDuration,
                maxTotalFee: type(uint256).max
            })
        );
        deal({ token: rushERC20, to: address(rushSmartLock), give: defaults.STAKING_AMOUNT() });
        deal({ token: address(weth), to: uniV2Pair, give: liquidityAmount + defaults.EARLY_UNWIND_THRESHOLD() });
        IUniswapV2Pair(uniV2Pair).sync();
        liquidityDeployer.unwindLiquidity({ uniV2Pair: uniV2Pair });
        resetPrank({ msgSender: caller });
    }

    /// @dev Sets the LiquidityDeployer address on the RushSmartLock contract.
    function setLiquidityDeployer() internal {
        (, address caller,) = vm.readCallers();
        resetPrank({ msgSender: users.admin });
        rushSmartLock.setLiquidityDeployer(address(liquidityDeployer));
        resetPrank({ msgSender: caller });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

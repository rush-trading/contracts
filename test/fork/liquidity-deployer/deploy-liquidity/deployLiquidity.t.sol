// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Errors } from "src/libraries/Errors.sol";
import { LD } from "src/types/DataTypes.sol";
import { GoodRushERC20Mock } from "test/mocks/GoodRushERC20Mock.sol";
import { LiquidityDeployer_Fork_Test } from "../LiquidityDeployer.t.sol";

contract DeployLiquidity_Fork_Test is LiquidityDeployer_Fork_Test {
    function test_RevertWhen_CallerDoesNotHaveLauncherRole() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        uint256 amount = defaults.LIQUIDITY_AMOUNT();
        uint256 duration = defaults.LIQUIDITY_DURATION();
        vm.expectRevert(abi.encodeWithSelector(Errors.OnlyLauncherRole.selector, users.eve));
        liquidityDeployer.deployLiquidity({
            originator: users.sender,
            uniV2Pair: uniV2Pair,
            rushERC20: rushERC20Mock,
            amount: amount,
            duration: duration
        });
    }

    modifier whenCallerHasLauncherRole() {
        // Make Launcher the caller in this test.
        resetPrank({ msgSender: users.launcher });
        _;
    }

    function test_RevertWhen_ContractIsPaused() external whenCallerHasLauncherRole {
        // Pause the contract.
        pause();

        // Run the test.
        uint256 amount = defaults.LIQUIDITY_AMOUNT();
        uint256 duration = defaults.LIQUIDITY_DURATION();
        vm.expectRevert(abi.encodeWithSelector(Errors.EnforcedPause.selector));
        liquidityDeployer.deployLiquidity({
            originator: users.sender,
            uniV2Pair: uniV2Pair,
            rushERC20: rushERC20Mock,
            amount: amount,
            duration: duration
        });
    }

    modifier whenContractIsNotPaused() {
        _;
    }

    function test_RevertGiven_PairHasAlreadyReceivedLiquidity()
        external
        whenCallerHasLauncherRole
        whenContractIsNotPaused
    {
        uint256 amount = defaults.LIQUIDITY_AMOUNT();
        uint256 duration = defaults.LIQUIDITY_DURATION();
        uint256 feeAmount = getDeployLiquidityFee({ amount: amount, duration: duration });

        // Deploy the liquidity.
        deployLiquidity({
            originator_: users.sender,
            uniV2Pair_: uniV2Pair,
            rushERC20_: rushERC20Mock,
            rushERC20Amount_: defaults.RUSH_ERC20_SUPPLY(),
            wethAmount_: amount,
            duration_: duration,
            feeAmount_: feeAmount
        });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LiquidityDeployer_PairAlreadyReceivedLiquidity.selector, rushERC20Mock, uniV2Pair
            )
        );
        liquidityDeployer.deployLiquidity{ value: feeAmount }({
            originator: users.sender,
            uniV2Pair: uniV2Pair,
            rushERC20: rushERC20Mock,
            amount: amount,
            duration: duration
        });
    }

    modifier givenPairHasNotReceivedLiquidity() {
        _;
    }

    function test_RevertGiven_TotalSupplyOfRushERC20IsZero()
        external
        whenCallerHasLauncherRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
    {
        // Run the test.
        uint256 amount = defaults.LIQUIDITY_AMOUNT();
        uint256 duration = defaults.LIQUIDITY_DURATION();
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LiquidityDeployer_TotalSupplyZero.selector, rushERC20Mock, uniV2Pair)
        );
        liquidityDeployer.deployLiquidity({
            originator: users.sender,
            uniV2Pair: uniV2Pair,
            rushERC20: rushERC20Mock,
            amount: amount,
            duration: duration
        });
    }

    modifier givenTotalSupplyOfRushERC20IsNotZero() {
        _;
    }

    function test_RevertGiven_PairDoesNotHoldEntireSupplyOfRushERC20()
        external
        whenCallerHasLauncherRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
        givenTotalSupplyOfRushERC20IsNotZero
    {
        // Mint total supply of RushERC20 to a non-pair address.
        GoodRushERC20Mock(rushERC20Mock).mint({ account: users.recipient, amount: defaults.MAX_RUSH_ERC20_SUPPLY() });

        // Run the test.
        uint256 amount = defaults.LIQUIDITY_AMOUNT();
        uint256 duration = defaults.LIQUIDITY_DURATION();
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LiquidityDeployer_PairSupplyDiscrepancy.selector,
                rushERC20Mock,
                uniV2Pair,
                0,
                defaults.MAX_RUSH_ERC20_SUPPLY()
            )
        );
        liquidityDeployer.deployLiquidity({
            originator: users.sender,
            uniV2Pair: uniV2Pair,
            rushERC20: rushERC20Mock,
            amount: amount,
            duration: duration
        });
    }

    modifier givenPairHoldsEntireSupplyOfRushERC20() {
        GoodRushERC20Mock(rushERC20Mock).mint({ account: uniV2Pair, amount: defaults.MAX_RUSH_ERC20_SUPPLY() });
        _;
    }

    function test_RevertGiven_AmountToDeployIsLessThanMinimumAmount()
        external
        whenCallerHasLauncherRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
        givenTotalSupplyOfRushERC20IsNotZero
        givenPairHoldsEntireSupplyOfRushERC20
    {
        // Run the test.
        uint256 amount = defaults.MIN_LIQUIDITY_AMOUNT() - 1;
        uint256 duration = defaults.LIQUIDITY_DURATION();
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_MinLiquidtyAmount.selector, amount));
        liquidityDeployer.deployLiquidity({
            originator: users.sender,
            uniV2Pair: uniV2Pair,
            rushERC20: rushERC20Mock,
            amount: amount,
            duration: duration
        });
    }

    modifier givenAmountToDeployIsGreaterThanOrEqualToMinimumAmount() {
        _;
    }

    function test_RevertGiven_AmountToDeployIsGreaterThanMaximumAmount()
        external
        whenCallerHasLauncherRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
        givenTotalSupplyOfRushERC20IsNotZero
        givenPairHoldsEntireSupplyOfRushERC20
        givenAmountToDeployIsGreaterThanOrEqualToMinimumAmount
    {
        // Run the test.
        uint256 amount = defaults.MAX_LIQUIDITY_AMOUNT() + 1;
        uint256 duration = defaults.LIQUIDITY_DURATION();
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_MaxLiquidtyAmount.selector, amount));
        liquidityDeployer.deployLiquidity({
            originator: users.sender,
            uniV2Pair: uniV2Pair,
            rushERC20: rushERC20Mock,
            amount: amount,
            duration: duration
        });
    }

    modifier givenAmountToDeployIsLessThanOrEqualToMaximumAmount() {
        _;
    }

    function test_RevertGiven_DurationOfDeploymentIsLessThanMinimumDuration()
        external
        whenCallerHasLauncherRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
        givenTotalSupplyOfRushERC20IsNotZero
        givenPairHoldsEntireSupplyOfRushERC20
        givenAmountToDeployIsGreaterThanOrEqualToMinimumAmount
        givenAmountToDeployIsLessThanOrEqualToMaximumAmount
    {
        // Run the test.
        uint256 amount = defaults.LIQUIDITY_AMOUNT();
        uint256 duration = defaults.MIN_LIQUIDITY_DURATION() - 1;
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_MinDuration.selector, duration));
        liquidityDeployer.deployLiquidity({
            originator: users.sender,
            uniV2Pair: uniV2Pair,
            rushERC20: rushERC20Mock,
            amount: amount,
            duration: duration
        });
    }

    modifier givenDurationOfDeploymentIsGreaterThanOrEqualToMinimumDuration() {
        _;
    }

    function test_RevertGiven_DurationOfDeploymentIsGreaterThanMaximumDuration()
        external
        whenCallerHasLauncherRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
        givenTotalSupplyOfRushERC20IsNotZero
        givenPairHoldsEntireSupplyOfRushERC20
        givenAmountToDeployIsGreaterThanOrEqualToMinimumAmount
        givenAmountToDeployIsLessThanOrEqualToMaximumAmount
        givenDurationOfDeploymentIsGreaterThanOrEqualToMinimumDuration
    {
        // Run the test.
        uint256 amount = defaults.LIQUIDITY_AMOUNT();
        uint256 duration = defaults.MAX_LIQUIDITY_DURATION() + 1;
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_MaxDuration.selector, duration));
        liquidityDeployer.deployLiquidity({
            originator: users.sender,
            uniV2Pair: uniV2Pair,
            rushERC20: rushERC20Mock,
            amount: amount,
            duration: duration
        });
    }

    modifier givenDurationOfDeploymentIsLessThanOrEqualToMaximumDuration() {
        _;
    }

    function test_RevertGiven_PassedMsgValueIsLessThanDeploymentFee()
        external
        whenCallerHasLauncherRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
        givenTotalSupplyOfRushERC20IsNotZero
        givenPairHoldsEntireSupplyOfRushERC20
        givenAmountToDeployIsGreaterThanOrEqualToMinimumAmount
        givenAmountToDeployIsLessThanOrEqualToMaximumAmount
        givenDurationOfDeploymentIsGreaterThanOrEqualToMinimumDuration
        givenDurationOfDeploymentIsLessThanOrEqualToMaximumDuration
    {
        // Run the test.
        uint256 amount = defaults.LIQUIDITY_AMOUNT();
        uint256 duration = defaults.LIQUIDITY_DURATION();
        uint256 msgValue = 0;
        uint256 feeAmount = getDeployLiquidityFee({ amount: amount, duration: duration });
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_FeeMismatch.selector, feeAmount, 0));
        liquidityDeployer.deployLiquidity{ value: msgValue }({
            originator: users.sender,
            uniV2Pair: uniV2Pair,
            rushERC20: rushERC20Mock,
            amount: amount,
            duration: duration
        });
    }

    modifier givenPassedMsgValueIsGreaterThanOrEqualToDeploymentFee() {
        _;
    }

    struct Vars {
        uint256 amount;
        uint256 duration;
        uint256 feeAmount;
        uint256 feeExcessAmount;
        uint256 msgValue;
        address actualRushERC20;
        address actualOriginator;
        uint256 actualAmount;
        uint256 actualDeadline;
        bool actualIsUnwound;
        address expectedRushERC20;
        address expectedOriginator;
        uint256 expectedAmount;
        uint256 expectedDeadline;
        bool expectedIsUnwound;
        uint256 wethBalanceOfLiquidtyPoolBefore;
        uint256 wethBalanceOfPairBefore;
        uint256 wethBalanceOfLiquidtyPoolAfter;
        uint256 wethBalanceOfPairAfter;
        uint256 rushERC20BalanceOfSenderBefore;
        uint256 rushERC20BalanceOfSenderAfter;
        uint256 reserveFee;
        uint256 expectedBalanceDiff;
        uint256 expectedRushERC20Amount;
    }

    function test_GivenExcessMsgValueIsEqualToZero()
        external
        whenCallerHasLauncherRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
        givenTotalSupplyOfRushERC20IsNotZero
        givenPairHoldsEntireSupplyOfRushERC20
        givenAmountToDeployIsGreaterThanOrEqualToMinimumAmount
        givenAmountToDeployIsLessThanOrEqualToMaximumAmount
        givenDurationOfDeploymentIsGreaterThanOrEqualToMinimumDuration
        givenDurationOfDeploymentIsLessThanOrEqualToMaximumDuration
        givenPassedMsgValueIsGreaterThanOrEqualToDeploymentFee
    {
        Vars memory vars;
        vars.amount = defaults.LIQUIDITY_AMOUNT();
        vars.duration = defaults.LIQUIDITY_DURATION();
        vars.feeAmount = getDeployLiquidityFee({ amount: vars.amount, duration: vars.duration });
        vars.msgValue = vars.feeAmount;

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(liquidityDeployer) });
        emit DeployLiquidity({
            originator: users.sender,
            uniV2Pair: uniV2Pair,
            rushERC20: rushERC20Mock,
            amount: vars.amount,
            totalFee: vars.feeAmount,
            reserveFee: Math.mulDiv(vars.feeAmount, defaults.RESERVE_FACTOR(), 1e18),
            deadline: block.timestamp + vars.duration
        });

        // Deploy the liquidity.
        vars.wethBalanceOfPairBefore = weth.balanceOf({ account: uniV2Pair });
        vars.wethBalanceOfLiquidtyPoolBefore = weth.balanceOf({ account: liquidityDeployer.LIQUIDITY_POOL() });
        vars.rushERC20BalanceOfSenderBefore = GoodRushERC20Mock(rushERC20Mock).balanceOf({ account: users.sender });
        liquidityDeployer.deployLiquidity{ value: vars.msgValue }({
            originator: users.sender,
            uniV2Pair: uniV2Pair,
            rushERC20: rushERC20Mock,
            amount: vars.amount,
            duration: vars.duration
        });
        vars.wethBalanceOfPairAfter = weth.balanceOf({ account: uniV2Pair });
        vars.wethBalanceOfLiquidtyPoolAfter = weth.balanceOf({ account: liquidityDeployer.LIQUIDITY_POOL() });
        vars.rushERC20BalanceOfSenderAfter = GoodRushERC20Mock(rushERC20Mock).balanceOf({ account: users.sender });

        // Assert that the liquidity was deployed.
        vars.reserveFee = Math.mulDiv(vars.feeAmount, defaults.RESERVE_FACTOR(), 1e18);
        vars.expectedBalanceDiff = vars.amount + vars.reserveFee;
        assertEq(vars.wethBalanceOfPairAfter - vars.wethBalanceOfPairBefore, vars.expectedBalanceDiff, "balanceOf");
        // Assert that the LiquidityPool balance is correct after deployment.
        // (100% - reserveFactor) of the total fee amount is added back to the LiquidityPool as APY.
        vars.expectedBalanceDiff =
            vars.amount - Math.mulDiv(vars.feeAmount, 1e18 - defaults.RESERVE_FACTOR(), 1e18, Math.Rounding.Ceil);
        assertEq(
            vars.wethBalanceOfLiquidtyPoolBefore - vars.wethBalanceOfLiquidtyPoolAfter,
            vars.expectedBalanceDiff,
            "balanceOf"
        );

        LD.LiquidityDeployment memory liquidityDeployment = liquidityDeployer.getLiquidityDeployment(uniV2Pair);
        (vars.actualRushERC20, vars.actualOriginator, vars.actualAmount, vars.actualDeadline, vars.actualIsUnwound) = (
            liquidityDeployment.rushERC20,
            liquidityDeployment.originator,
            liquidityDeployment.amount,
            liquidityDeployment.deadline,
            liquidityDeployment.isUnwound
        );
        vars.expectedRushERC20 = rushERC20Mock;
        vars.expectedOriginator = users.sender;
        vars.expectedAmount = vars.amount;
        vars.expectedDeadline = block.timestamp + vars.duration;
        vars.expectedIsUnwound = false;
        assertEq(vars.actualRushERC20, vars.expectedRushERC20, "rushERC20");
        assertEq(vars.actualOriginator, vars.expectedOriginator, "originator");
        assertEq(vars.actualAmount, vars.expectedAmount, "amount");
        assertEq(vars.actualDeadline, vars.expectedDeadline, "deadline");
        assertEq(vars.actualIsUnwound, vars.expectedIsUnwound, "isUnwound");

        // Assert that the original caller received no RushERC20 amount.
        vars.expectedRushERC20Amount = 0;
        assertEq(
            vars.rushERC20BalanceOfSenderAfter - vars.rushERC20BalanceOfSenderBefore,
            vars.expectedRushERC20Amount,
            "balanceOf"
        );
    }

    function test_GivenExcessMsgValueIsGreaterThanZero()
        external
        whenCallerHasLauncherRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
        givenTotalSupplyOfRushERC20IsNotZero
        givenPairHoldsEntireSupplyOfRushERC20
        givenAmountToDeployIsGreaterThanOrEqualToMinimumAmount
        givenAmountToDeployIsLessThanOrEqualToMaximumAmount
        givenDurationOfDeploymentIsGreaterThanOrEqualToMinimumDuration
        givenDurationOfDeploymentIsLessThanOrEqualToMaximumDuration
        givenPassedMsgValueIsGreaterThanOrEqualToDeploymentFee
    {
        Vars memory vars;
        vars.amount = defaults.LIQUIDITY_AMOUNT();
        vars.duration = defaults.LIQUIDITY_DURATION();
        vars.feeAmount = getDeployLiquidityFee({ amount: vars.amount, duration: vars.duration });
        vars.feeExcessAmount = 0.00042 ether;
        vars.msgValue = vars.feeAmount + vars.feeExcessAmount;

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(liquidityDeployer) });
        emit DeployLiquidity({
            originator: users.sender,
            uniV2Pair: uniV2Pair,
            rushERC20: rushERC20Mock,
            amount: vars.amount,
            totalFee: vars.feeAmount,
            reserveFee: Math.mulDiv(vars.feeAmount, defaults.RESERVE_FACTOR(), 1e18),
            deadline: block.timestamp + vars.duration
        });

        // Deploy the liquidity.
        vars.wethBalanceOfPairBefore = weth.balanceOf({ account: uniV2Pair });
        vars.wethBalanceOfLiquidtyPoolBefore = weth.balanceOf({ account: liquidityDeployer.LIQUIDITY_POOL() });
        vars.rushERC20BalanceOfSenderBefore = GoodRushERC20Mock(rushERC20Mock).balanceOf({ account: users.sender });
        liquidityDeployer.deployLiquidity{ value: vars.msgValue }({
            originator: users.sender,
            uniV2Pair: uniV2Pair,
            rushERC20: rushERC20Mock,
            amount: vars.amount,
            duration: vars.duration
        });
        vars.wethBalanceOfPairAfter = weth.balanceOf({ account: uniV2Pair });
        vars.wethBalanceOfLiquidtyPoolAfter = weth.balanceOf({ account: liquidityDeployer.LIQUIDITY_POOL() });
        vars.rushERC20BalanceOfSenderAfter = GoodRushERC20Mock(rushERC20Mock).balanceOf({ account: users.sender });

        // Assert that the liquidity was deployed.
        vars.reserveFee = Math.mulDiv(vars.feeAmount, defaults.RESERVE_FACTOR(), 1e18);
        vars.expectedBalanceDiff = vars.amount + vars.feeExcessAmount + vars.reserveFee;
        assertEq(vars.wethBalanceOfPairAfter - vars.wethBalanceOfPairBefore, vars.expectedBalanceDiff, "balanceOf");
        // Assert that the LiquidityPool balance is correct after deployment.
        // (100% - reserveFactor) of the total fee amount is added back to the LiquidityPool as APY.
        vars.expectedBalanceDiff =
            vars.amount - Math.mulDiv(vars.feeAmount, 1e18 - defaults.RESERVE_FACTOR(), 1e18, Math.Rounding.Ceil);
        assertEq(
            vars.wethBalanceOfLiquidtyPoolBefore - vars.wethBalanceOfLiquidtyPoolAfter,
            vars.expectedBalanceDiff,
            "balanceOf"
        );

        LD.LiquidityDeployment memory liquidityDeployment = liquidityDeployer.getLiquidityDeployment(uniV2Pair);
        (vars.actualRushERC20, vars.actualOriginator, vars.actualAmount, vars.actualDeadline, vars.actualIsUnwound) = (
            liquidityDeployment.rushERC20,
            liquidityDeployment.originator,
            liquidityDeployment.amount,
            liquidityDeployment.deadline,
            liquidityDeployment.isUnwound
        );
        vars.expectedRushERC20 = rushERC20Mock;
        vars.expectedOriginator = users.sender;
        vars.expectedAmount = vars.amount;
        vars.expectedDeadline = block.timestamp + vars.duration;
        vars.expectedIsUnwound = false;
        assertEq(vars.actualRushERC20, vars.expectedRushERC20, "rushERC20");
        assertEq(vars.actualOriginator, vars.expectedOriginator, "originator");
        assertEq(vars.actualAmount, vars.expectedAmount, "amount");
        assertEq(vars.actualDeadline, vars.expectedDeadline, "deadline");
        assertEq(vars.actualIsUnwound, vars.expectedIsUnwound, "isUnwound");

        // Assert that the original caller received a RushERC20 amount equivalent to the excess msg value.
        vars.expectedRushERC20Amount = calculateAmountOutFromExactIn({
            amountIn: vars.feeExcessAmount,
            reserveIn: defaults.LIQUIDITY_AMOUNT() + vars.reserveFee,
            reserveOut: defaults.MAX_RUSH_ERC20_SUPPLY()
        });
        assertEq(
            vars.rushERC20BalanceOfSenderAfter - vars.rushERC20BalanceOfSenderBefore,
            vars.expectedRushERC20Amount,
            "balanceOf"
        );
    }
}

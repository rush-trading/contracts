// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { ud } from "@prb/math/src/UD60x18.sol";
import { Errors } from "src/libraries/Errors.sol";
import { GoodRushERC20Mock } from "test/mocks/GoodRushERC20Mock.sol";
import { LiquidityDeployer_Fork_Test } from "../LiquidityDeployer.t.sol";

contract DeployLiquidity_Fork_Test is LiquidityDeployer_Fork_Test {
    function test_RevertWhen_CallerDoesNotHaveLiquidityDeployerRole() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        uint256 amount = defaults.DISPATCH_AMOUNT();
        uint256 duration = defaults.LIQUIDITY_DURATION();
        vm.expectRevert(
            abi.encodeWithSelector(Errors.AccessControlUnauthorizedAccount.selector, users.eve, LIQUIDITY_DEPLOYER_ROLE)
        );
        liquidityDeployer.deployLiquidity({
            originator: users.sender,
            uniV2Pair: uniV2Pair,
            rushERC20: rushERC20Mock,
            amount: amount,
            duration: duration
        });
    }

    modifier whenCallerHasLiquidityDeployerRole() {
        // Make LiquidityDeployer the caller in this test.
        resetPrank({ msgSender: address(users.liquidityDeployer) });
        _;
    }

    function test_RevertWhen_ContractIsPaused() external whenCallerHasLiquidityDeployerRole {
        // Pause the contract.
        pause();

        // Run the test.
        uint256 amount = defaults.DISPATCH_AMOUNT();
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
        whenCallerHasLiquidityDeployerRole
        whenContractIsNotPaused
    {
        uint256 amount = defaults.DISPATCH_AMOUNT();
        uint256 duration = defaults.LIQUIDITY_DURATION();
        uint256 msgValue = defaults.FEE_AMOUNT();

        // Deploy the liquidity.
        deployLiquidity({
            originator_: users.sender,
            uniV2Pair_: uniV2Pair,
            rushERC20_: rushERC20Mock,
            rushERC20Amount_: defaults.RUSH_ERC20_MAX_SUPPLY(),
            wethAmount_: amount,
            duration_: duration,
            feeAmount_: msgValue
        });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LiquidityDeployer_PairAlreadyReceivedLiquidity.selector, rushERC20Mock, uniV2Pair
            )
        );
        liquidityDeployer.deployLiquidity{ value: msgValue }({
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
        whenCallerHasLiquidityDeployerRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
    {
        // Run the test.
        uint256 amount = defaults.DISPATCH_AMOUNT();
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

    function test_RevertGiven_PairDoesNotContainEntireSupplyOfRushERC20()
        external
        whenCallerHasLiquidityDeployerRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
        givenTotalSupplyOfRushERC20IsNotZero
    {
        // Mint total supply of RushERC20 to a non-pair address.
        GoodRushERC20Mock(rushERC20Mock).mint({ account: users.recipient, amount: defaults.RUSH_ERC20_MAX_SUPPLY() });

        // Run the test.
        uint256 amount = defaults.DISPATCH_AMOUNT();
        uint256 duration = defaults.LIQUIDITY_DURATION();
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LiquidityDeployer_PairSupplyDiscrepancy.selector,
                rushERC20Mock,
                uniV2Pair,
                0,
                defaults.RUSH_ERC20_MAX_SUPPLY()
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

    modifier givenPairContainsEntireSupplyOfRushERC20() {
        GoodRushERC20Mock(rushERC20Mock).mint({ account: uniV2Pair, amount: defaults.RUSH_ERC20_MAX_SUPPLY() });
        _;
    }

    function test_RevertGiven_AmountToDeployIsLessThanMinimumAmount()
        external
        whenCallerHasLiquidityDeployerRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
        givenTotalSupplyOfRushERC20IsNotZero
        givenPairContainsEntireSupplyOfRushERC20
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
        whenCallerHasLiquidityDeployerRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
        givenTotalSupplyOfRushERC20IsNotZero
        givenPairContainsEntireSupplyOfRushERC20
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
        whenCallerHasLiquidityDeployerRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
        givenTotalSupplyOfRushERC20IsNotZero
        givenPairContainsEntireSupplyOfRushERC20
        givenAmountToDeployIsGreaterThanOrEqualToMinimumAmount
        givenAmountToDeployIsLessThanOrEqualToMaximumAmount
    {
        // Run the test.
        uint256 amount = defaults.DISPATCH_AMOUNT();
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
        whenCallerHasLiquidityDeployerRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
        givenTotalSupplyOfRushERC20IsNotZero
        givenPairContainsEntireSupplyOfRushERC20
        givenAmountToDeployIsGreaterThanOrEqualToMinimumAmount
        givenAmountToDeployIsLessThanOrEqualToMaximumAmount
        givenDurationOfDeploymentIsGreaterThanOrEqualToMinimumDuration
    {
        // Run the test.
        uint256 amount = defaults.DISPATCH_AMOUNT();
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
        whenCallerHasLiquidityDeployerRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
        givenTotalSupplyOfRushERC20IsNotZero
        givenPairContainsEntireSupplyOfRushERC20
        givenAmountToDeployIsGreaterThanOrEqualToMinimumAmount
        givenAmountToDeployIsLessThanOrEqualToMaximumAmount
        givenDurationOfDeploymentIsGreaterThanOrEqualToMinimumDuration
        givenDurationOfDeploymentIsLessThanOrEqualToMaximumDuration
    {
        // Run the test.
        uint256 amount = defaults.DISPATCH_AMOUNT();
        uint256 duration = defaults.LIQUIDITY_DURATION();
        uint256 msgValue = 0;
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_FeeMismatch.selector, defaults.FEE_AMOUNT(), 0));
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
        uint256 wethBalanceBefore;
        uint256 wethBalanceAfter;
        uint256 rushERC20BalanceOfSenderBefore;
        uint256 rushERC20BalanceOfSenderAfter;
        uint256 reserveFee;
        uint256 expectedBalanceDiff;
        uint256 expectedRushERC20Amount;
    }

    function test_GivenExcessMsgValueIsEqualToZero()
        external
        whenCallerHasLiquidityDeployerRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
        givenTotalSupplyOfRushERC20IsNotZero
        givenPairContainsEntireSupplyOfRushERC20
        givenAmountToDeployIsGreaterThanOrEqualToMinimumAmount
        givenAmountToDeployIsLessThanOrEqualToMaximumAmount
        givenDurationOfDeploymentIsGreaterThanOrEqualToMinimumDuration
        givenDurationOfDeploymentIsLessThanOrEqualToMaximumDuration
        givenPassedMsgValueIsGreaterThanOrEqualToDeploymentFee
    {
        Vars memory vars;
        vars.amount = defaults.DISPATCH_AMOUNT();
        vars.duration = defaults.LIQUIDITY_DURATION();
        vars.msgValue = defaults.FEE_AMOUNT();

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(liquidityDeployer) });
        emit DeployLiquidity({
            originator: users.sender,
            uniV2Pair: uniV2Pair,
            rushERC20: rushERC20Mock,
            amount: vars.amount,
            deadline: block.timestamp + vars.duration
        });

        // Deploy the liquidity.
        vars.wethBalanceBefore = weth.balanceOf({ account: uniV2Pair });
        vars.rushERC20BalanceOfSenderBefore = GoodRushERC20Mock(rushERC20Mock).balanceOf({ account: users.sender });
        liquidityDeployer.deployLiquidity{ value: vars.msgValue }({
            originator: users.sender,
            uniV2Pair: uniV2Pair,
            rushERC20: rushERC20Mock,
            amount: vars.amount,
            duration: vars.duration
        });
        vars.wethBalanceAfter = weth.balanceOf({ account: uniV2Pair });
        vars.rushERC20BalanceOfSenderAfter = GoodRushERC20Mock(rushERC20Mock).balanceOf({ account: users.sender });

        // Assert that the liquidity was deployed.
        vars.reserveFee = (ud(vars.msgValue) * ud(defaults.RESERVE_FACTOR())).intoUint256();
        vars.expectedBalanceDiff = vars.amount + vars.reserveFee;
        assertEq(vars.wethBalanceAfter - vars.wethBalanceBefore, vars.expectedBalanceDiff, "balanceOf");

        (vars.actualRushERC20, vars.actualOriginator, vars.actualAmount, vars.actualDeadline, vars.actualIsUnwound) =
            liquidityDeployer.liquidityDeployments(uniV2Pair);
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

        // TODO check the state of LiquidityPool as well.
    }

    function test_GivenExcessMsgValueIsGreaterThanZero()
        external
        whenCallerHasLiquidityDeployerRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
        givenTotalSupplyOfRushERC20IsNotZero
        givenPairContainsEntireSupplyOfRushERC20
        givenAmountToDeployIsGreaterThanOrEqualToMinimumAmount
        givenAmountToDeployIsLessThanOrEqualToMaximumAmount
        givenDurationOfDeploymentIsGreaterThanOrEqualToMinimumDuration
        givenDurationOfDeploymentIsLessThanOrEqualToMaximumDuration
        givenPassedMsgValueIsGreaterThanOrEqualToDeploymentFee
    {
        Vars memory vars;
        vars.amount = defaults.DISPATCH_AMOUNT();
        vars.duration = defaults.LIQUIDITY_DURATION();
        vars.msgValue = defaults.FEE_AMOUNT() + defaults.FEE_EXCESS_AMOUNT();

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(liquidityDeployer) });
        emit DeployLiquidity({
            originator: users.sender,
            uniV2Pair: uniV2Pair,
            rushERC20: rushERC20Mock,
            amount: vars.amount,
            deadline: block.timestamp + vars.duration
        });

        // Deploy the liquidity.
        vars.wethBalanceBefore = weth.balanceOf({ account: uniV2Pair });
        vars.rushERC20BalanceOfSenderBefore = GoodRushERC20Mock(rushERC20Mock).balanceOf({ account: users.sender });
        liquidityDeployer.deployLiquidity{ value: vars.msgValue }({
            originator: users.sender,
            uniV2Pair: uniV2Pair,
            rushERC20: rushERC20Mock,
            amount: vars.amount,
            duration: vars.duration
        });
        vars.wethBalanceAfter = weth.balanceOf({ account: uniV2Pair });
        vars.rushERC20BalanceOfSenderAfter = GoodRushERC20Mock(rushERC20Mock).balanceOf({ account: users.sender });

        // Assert that the liquidity was deployed.
        vars.reserveFee = (ud(defaults.FEE_AMOUNT()) * ud(defaults.RESERVE_FACTOR())).intoUint256();
        vars.expectedBalanceDiff = vars.amount + defaults.FEE_EXCESS_AMOUNT() + vars.reserveFee;
        assertEq(vars.wethBalanceAfter - vars.wethBalanceBefore, vars.expectedBalanceDiff, "balanceOf");

        (vars.actualRushERC20, vars.actualOriginator, vars.actualAmount, vars.actualDeadline, vars.actualIsUnwound) =
            liquidityDeployer.liquidityDeployments(uniV2Pair);
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
        vars.expectedRushERC20Amount = calculateExactAmountOut({
            amountIn: defaults.FEE_EXCESS_AMOUNT(),
            reserveIn: defaults.DISPATCH_AMOUNT() + vars.reserveFee,
            reserveOut: defaults.RUSH_ERC20_MAX_SUPPLY()
        });
        assertEq(
            vars.rushERC20BalanceOfSenderAfter - vars.rushERC20BalanceOfSenderBefore,
            vars.expectedRushERC20Amount,
            "balanceOf"
        );
    }
}

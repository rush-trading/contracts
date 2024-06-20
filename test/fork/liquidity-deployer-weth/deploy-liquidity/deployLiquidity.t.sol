// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { ud } from "@prb/math/src/UD60x18.sol";
import { Errors } from "src/libraries/Errors.sol";
import { GoodRushERC20Mock } from "test/mocks/GoodRushERC20Mock.sol";
import { LiquidityDeployerWETH_Fork_Test } from "../LiquidityDeployerWETH.t.sol";

contract DeployLiquidity_Fork_Test is LiquidityDeployerWETH_Fork_Test {
    function test_RevertWhen_CallerDoesNotHaveLiquidityDeployerRole() external {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        uint256 amount = defaults.DISPATCH_AMOUNT();
        uint256 duration = defaults.LIQUIDITY_DURATION();
        vm.expectRevert(
            abi.encodeWithSelector(Errors.AccessControlUnauthorizedAccount.selector, users.eve, LIQUIDITY_DEPLOYER_ROLE)
        );
        liquidityDeployerWETH.deployLiquidity({
            originator: users.sender,
            pair: pair,
            token: token,
            amount: amount,
            duration: duration
        });
    }

    modifier whenCallerHasLiquidityDeployerRole() {
        // Make LiquidityDeployer the caller in this test.
        changePrank({ msgSender: address(users.liquidityDeployer) });
        _;
    }

    function test_RevertWhen_ContractIsPaused() external whenCallerHasLiquidityDeployerRole {
        // Pause the contract.
        pauseContract();

        // Run the test.
        uint256 amount = defaults.DISPATCH_AMOUNT();
        uint256 duration = defaults.LIQUIDITY_DURATION();
        vm.expectRevert(abi.encodeWithSelector(Errors.EnforcedPause.selector));
        liquidityDeployerWETH.deployLiquidity({
            originator: users.sender,
            pair: pair,
            token: token,
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
        uint256 feeAmount = defaults.FEE_AMOUNT();

        // Deploy the liquidity.
        deployLiquidityToPair({
            originator_: users.sender,
            pair_: pair,
            token_: token,
            tokenAmount_: defaults.TOKEN_MAX_SUPPLY(),
            wethAmount_: amount,
            duration_: duration,
            feeAmount_: feeAmount
        });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LiquidityDeployer_PairAlreadyReceivedLiquidity.selector, token, pair)
        );
        liquidityDeployerWETH.deployLiquidity{ value: feeAmount }({
            originator: users.sender,
            pair: pair,
            token: token,
            amount: amount,
            duration: duration
        });
    }

    modifier givenPairHasNotReceivedLiquidity() {
        _;
    }

    function test_RevertGiven_TotalSupplyOfDeployedTokenIsZero()
        external
        whenCallerHasLiquidityDeployerRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
    {
        // Run the test.
        uint256 amount = defaults.DISPATCH_AMOUNT();
        uint256 duration = defaults.LIQUIDITY_DURATION();
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_TotalSupplyZero.selector, token, pair));
        liquidityDeployerWETH.deployLiquidity({
            originator: users.sender,
            pair: pair,
            token: token,
            amount: amount,
            duration: duration
        });
    }

    modifier givenTotalSupplyOfDeployedTokenIsNotZero() {
        _;
    }

    function test_RevertGiven_PairDoesNotContainEntireSupplyOfDeployedToken()
        external
        whenCallerHasLiquidityDeployerRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
        givenTotalSupplyOfDeployedTokenIsNotZero
    {
        // Mint total supply of token to a non-pair address.
        GoodRushERC20Mock(token).mint({ account: users.recipient, amount: defaults.TOKEN_MAX_SUPPLY() });

        // Run the test.
        uint256 amount = defaults.DISPATCH_AMOUNT();
        uint256 duration = defaults.LIQUIDITY_DURATION();
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LiquidityDeployer_PairSupplyDiscrepancy.selector, token, pair, 0, defaults.TOKEN_MAX_SUPPLY()
            )
        );
        liquidityDeployerWETH.deployLiquidity({
            originator: users.sender,
            pair: pair,
            token: token,
            amount: amount,
            duration: duration
        });
    }

    modifier givenPairContainsEntireSupplyOfDeployedToken() {
        GoodRushERC20Mock(token).mint({ account: pair, amount: defaults.TOKEN_MAX_SUPPLY() });
        _;
    }

    function test_RevertGiven_AmountToDeployIsLessThanMinimumAmount()
        external
        whenCallerHasLiquidityDeployerRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
        givenTotalSupplyOfDeployedTokenIsNotZero
        givenPairContainsEntireSupplyOfDeployedToken
    {
        // Run the test.
        uint256 amount = defaults.MIN_LIQUIDITY_AMOUNT() - 1;
        uint256 duration = defaults.LIQUIDITY_DURATION();
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_MinLiquidtyAmount.selector, amount));
        liquidityDeployerWETH.deployLiquidity({
            originator: users.sender,
            pair: pair,
            token: token,
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
        givenTotalSupplyOfDeployedTokenIsNotZero
        givenPairContainsEntireSupplyOfDeployedToken
        givenAmountToDeployIsGreaterThanOrEqualToMinimumAmount
    {
        // Run the test.
        uint256 amount = defaults.MAX_LIQUIDITY_AMOUNT() + 1;
        uint256 duration = defaults.LIQUIDITY_DURATION();
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_MaxLiquidtyAmount.selector, amount));
        liquidityDeployerWETH.deployLiquidity({
            originator: users.sender,
            pair: pair,
            token: token,
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
        givenTotalSupplyOfDeployedTokenIsNotZero
        givenPairContainsEntireSupplyOfDeployedToken
        givenAmountToDeployIsGreaterThanOrEqualToMinimumAmount
        givenAmountToDeployIsLessThanOrEqualToMaximumAmount
    {
        // Run the test.
        uint256 amount = defaults.DISPATCH_AMOUNT();
        uint256 duration = defaults.MIN_LIQUIDITY_DURATION() - 1;
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_MinDuration.selector, duration));
        liquidityDeployerWETH.deployLiquidity({
            originator: users.sender,
            pair: pair,
            token: token,
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
        givenTotalSupplyOfDeployedTokenIsNotZero
        givenPairContainsEntireSupplyOfDeployedToken
        givenAmountToDeployIsGreaterThanOrEqualToMinimumAmount
        givenAmountToDeployIsLessThanOrEqualToMaximumAmount
        givenDurationOfDeploymentIsGreaterThanOrEqualToMinimumDuration
    {
        // Run the test.
        uint256 amount = defaults.DISPATCH_AMOUNT();
        uint256 duration = defaults.MAX_LIQUIDITY_DURATION() + 1;
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_MaxDuration.selector, duration));
        liquidityDeployerWETH.deployLiquidity({
            originator: users.sender,
            pair: pair,
            token: token,
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
        givenTotalSupplyOfDeployedTokenIsNotZero
        givenPairContainsEntireSupplyOfDeployedToken
        givenAmountToDeployIsGreaterThanOrEqualToMinimumAmount
        givenAmountToDeployIsLessThanOrEqualToMaximumAmount
        givenDurationOfDeploymentIsGreaterThanOrEqualToMinimumDuration
        givenDurationOfDeploymentIsLessThanOrEqualToMaximumDuration
    {
        // Run the test.
        uint256 amount = defaults.DISPATCH_AMOUNT();
        uint256 duration = defaults.LIQUIDITY_DURATION();
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_FeeMismatch.selector, defaults.FEE_AMOUNT(), 0));
        liquidityDeployerWETH.deployLiquidity{ value: 0 }({
            originator: users.sender,
            pair: pair,
            token: token,
            amount: amount,
            duration: duration
        });
    }

    modifier givenPassedMsgValueIsGreaterThanOrEqualToDeploymentFee() {
        _;
    }

    function test_GivenExcessMsgValueIsEqualToZero()
        external
        whenCallerHasLiquidityDeployerRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
        givenTotalSupplyOfDeployedTokenIsNotZero
        givenPairContainsEntireSupplyOfDeployedToken
        givenAmountToDeployIsGreaterThanOrEqualToMinimumAmount
        givenAmountToDeployIsLessThanOrEqualToMaximumAmount
        givenDurationOfDeploymentIsGreaterThanOrEqualToMinimumDuration
        givenDurationOfDeploymentIsLessThanOrEqualToMaximumDuration
        givenPassedMsgValueIsGreaterThanOrEqualToDeploymentFee
    {
        uint256 amount = defaults.DISPATCH_AMOUNT();
        uint256 duration = defaults.LIQUIDITY_DURATION();

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(liquidityDeployerWETH) });
        emit DeployLiquidity({
            originator: users.sender,
            pair: pair,
            token: token,
            amount: amount,
            deadline: block.timestamp + duration
        });

        // Deploy the liquidity.
        uint256 wethBalanceBefore = weth.balanceOf({ account: pair });
        uint256 tokenBalanceOfSenderBefore = GoodRushERC20Mock(token).balanceOf({ account: users.sender });
        liquidityDeployerWETH.deployLiquidity{ value: defaults.FEE_AMOUNT() }({
            originator: users.sender,
            pair: pair,
            token: token,
            amount: amount,
            duration: duration
        });
        uint256 wethBalanceAfter = weth.balanceOf({ account: pair });
        uint256 tokenBalanceOfSenderAfter = GoodRushERC20Mock(token).balanceOf({ account: users.sender });

        // Assert that the liquidity was deployed.
        uint256 reserveFee = (ud(defaults.FEE_AMOUNT()) * ud(defaults.RESERVE_FACTOR())).intoUint256();
        uint256 expectedLiquidtyAmount = amount + reserveFee;
        assertEq(wethBalanceAfter - wethBalanceBefore, expectedLiquidtyAmount, "balanceOf");

        {
            (
                address actualToken,
                address actualOriginator,
                uint256 actualAmount,
                uint256 actualDeadline,
                bool actualIsUnwound
            ) = liquidityDeployerWETH.liquidityDeployments(pair);
            address expectedToken = token;
            address expectedOriginator = users.sender;
            uint256 expectedAmount = amount;
            uint256 expectedDeadline = block.timestamp + duration;
            bool expectedIsUnwound = false;
            assertEq(actualToken, expectedToken, "token");
            assertEq(actualOriginator, expectedOriginator, "originator");
            assertEq(actualAmount, expectedAmount, "amount");
            assertEq(actualDeadline, expectedDeadline, "deadline");
            assertEq(actualIsUnwound, expectedIsUnwound, "isUnwound");
        }

        // Assert that the original caller received no token amount.
        uint256 expectedTokenAmount = 0;
        assertEq(tokenBalanceOfSenderAfter - tokenBalanceOfSenderBefore, expectedTokenAmount, "balanceOf");

        // TODO check the state of LiquidityPool as well.
    }

    function test_GivenExcessMsgValueIsGreaterThanZero()
        external
        whenCallerHasLiquidityDeployerRole
        whenContractIsNotPaused
        givenPairHasNotReceivedLiquidity
        givenTotalSupplyOfDeployedTokenIsNotZero
        givenPairContainsEntireSupplyOfDeployedToken
        givenAmountToDeployIsGreaterThanOrEqualToMinimumAmount
        givenAmountToDeployIsLessThanOrEqualToMaximumAmount
        givenDurationOfDeploymentIsGreaterThanOrEqualToMinimumDuration
        givenDurationOfDeploymentIsLessThanOrEqualToMaximumDuration
        givenPassedMsgValueIsGreaterThanOrEqualToDeploymentFee
    {
        uint256 amount = defaults.DISPATCH_AMOUNT();
        uint256 duration = defaults.LIQUIDITY_DURATION();

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(liquidityDeployerWETH) });
        emit DeployLiquidity({
            originator: users.sender,
            pair: pair,
            token: token,
            amount: amount,
            deadline: block.timestamp + duration
        });

        // Deploy the liquidity.
        uint256 wethBalanceBefore = weth.balanceOf({ account: pair });
        uint256 tokenBalanceOfSenderBefore = GoodRushERC20Mock(token).balanceOf({ account: users.sender });
        liquidityDeployerWETH.deployLiquidity{ value: defaults.FEE_AMOUNT() + defaults.FEE_EXCESS_AMOUNT() }({
            originator: users.sender,
            pair: pair,
            token: token,
            amount: amount,
            duration: duration
        });
        uint256 wethBalanceAfter = weth.balanceOf({ account: pair });
        uint256 tokenBalanceOfSenderAfter = GoodRushERC20Mock(token).balanceOf({ account: users.sender });

        // Assert that the liquidity was deployed.
        uint256 reserveFee = (ud(defaults.FEE_AMOUNT()) * ud(defaults.RESERVE_FACTOR())).intoUint256();
        uint256 expectedLiquidtyAmount = amount + defaults.FEE_EXCESS_AMOUNT() + reserveFee;
        assertEq(wethBalanceAfter - wethBalanceBefore, expectedLiquidtyAmount, "balanceOf");

        {
            (
                address actualToken,
                address actualOriginator,
                uint256 actualAmount,
                uint256 actualDeadline,
                bool actualIsUnwound
            ) = liquidityDeployerWETH.liquidityDeployments(pair);
            address expectedToken = token;
            address expectedOriginator = users.sender;
            uint256 expectedAmount = amount;
            uint256 expectedDeadline = block.timestamp + duration;
            bool expectedIsUnwound = false;
            assertEq(actualToken, expectedToken, "token");
            assertEq(actualOriginator, expectedOriginator, "originator");
            assertEq(actualAmount, expectedAmount, "amount");
            assertEq(actualDeadline, expectedDeadline, "deadline");
            assertEq(actualIsUnwound, expectedIsUnwound, "isUnwound");
        }

        // Assert that the original caller received a token amount equivalent to the excess msg value.
        uint256 expectedTokenAmount = calculateExactAmountOut({
            amountIn: defaults.FEE_EXCESS_AMOUNT(),
            reserveIn: defaults.DISPATCH_AMOUNT() + reserveFee,
            reserveOut: defaults.TOKEN_MAX_SUPPLY()
        });
        assertEq(tokenBalanceOfSenderAfter - tokenBalanceOfSenderBefore, expectedTokenAmount, "balanceOf");
    }

    /// @dev Pauses the contract.
    function pauseContract() internal {
        (, address caller,) = vm.readCallers();
        changePrank({ msgSender: address(users.admin) });
        liquidityDeployerWETH.pause();
        changePrank({ msgSender: caller });
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Errors } from "src/libraries/Errors.sol";
import { LiquidityDeployerWETH_Fork_Test } from "../LiquidityDeployerWETH.t.sol";

contract UnwindLiquidityEMERGENCY__Fork_Test is LiquidityDeployerWETH_Fork_Test {
    function test_RevertWhen_CallerDoesNotHaveAdminRole() external {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        address[] memory pairs = new address[](1);
        pairs[0] = pair;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.AccessControlUnauthorizedAccount.selector, users.eve, DEFAULT_ADMIN_ROLE)
        );
        liquidityDeployerWETH.unwindLiquidityEMERGENCY({ pairs: pairs });
    }

    modifier whenCallerHasAdminRole() {
        changePrank({ msgSender: users.admin });
        _;
    }

    function test_RevertWhen_ContractIsNotPaused() external whenCallerHasAdminRole {
        // Run the test.
        address[] memory pairs = new address[](1);
        pairs[0] = pair;
        vm.expectRevert(abi.encodeWithSelector(Errors.ExpectedPause.selector));
        liquidityDeployerWETH.unwindLiquidityEMERGENCY({ pairs: pairs });
    }

    modifier whenContractIsPaused() {
        // Pause the contract.
        liquidityDeployerWETH.pause();
        _;
    }

    function test_RevertGiven_PairHasNotReceivedLiquidity() external whenCallerHasAdminRole whenContractIsPaused {
        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_PairNotReceivedLiquidity.selector, pair));
        address[] memory pairs = new address[](1);
        pairs[0] = pair;
        liquidityDeployerWETH.unwindLiquidityEMERGENCY({ pairs: pairs });
    }

    modifier givenPairHasReceivedLiquidity() {
        (, address caller,) = vm.readCallers();
        // Momentarily unpause the contract to deploy the liquidity.
        changePrank({ msgSender: address(users.admin) });
        liquidityDeployerWETH.unpause();
        // Deploy the liquidity.
        deployLiquidity({
            originator_: users.sender,
            pair_: pair,
            token_: token,
            tokenAmount_: defaults.TOKEN_MAX_SUPPLY(),
            wethAmount_: defaults.DISPATCH_AMOUNT(),
            duration_: defaults.LIQUIDITY_DURATION(),
            feeAmount_: defaults.FEE_AMOUNT()
        });
        // Pause the contract again.
        changePrank({ msgSender: address(users.admin) });
        liquidityDeployerWETH.pause();
        changePrank({ msgSender: caller });
        _;
    }

    function test_RevertGiven_PairHasAlreadyBeenUnwound()
        external
        whenCallerHasAdminRole
        whenContractIsPaused
        givenPairHasReceivedLiquidity
    {
        // Simulate the passage of time.
        (,,, uint256 deadline,) = liquidityDeployerWETH.liquidityDeployments(pair);
        vm.warp(deadline);

        // Unwind the liquidity.
        unwindLiquidity({ pair_: pair });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.LiquidityDeployer_PairAlreadyUnwound.selector, pair));
        address[] memory pairs = new address[](1);
        pairs[0] = pair;
        liquidityDeployerWETH.unwindLiquidityEMERGENCY({ pairs: pairs });
    }

    function test_GivenPairHasNotBeenUnwound()
        external
        whenCallerHasAdminRole
        whenContractIsPaused
        givenPairHasReceivedLiquidity
    {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(liquidityDeployerWETH) });
        emit UnwindLiquidity({ pair: pair, originator: users.sender, amount: defaults.DISPATCH_AMOUNT() });

        // Unwind the liquidity.
        address[] memory pairs = new address[](1);
        pairs[0] = pair;
        uint256 liquidityPoolWETHBalanceBefore = wethMock.balanceOf(address(liquidityPool));
        liquidityDeployerWETH.unwindLiquidityEMERGENCY({ pairs: pairs });
        uint256 liquidityPoolWETHBalanceAfter = wethMock.balanceOf(address(liquidityPool));

        // Assert that the liquidity was unwound.
        uint256 expectedLiquidtyPoolWETHBalanceDiff = defaults.DISPATCH_AMOUNT();
        vm.assertEq(
            liquidityPoolWETHBalanceAfter - liquidityPoolWETHBalanceBefore,
            expectedLiquidtyPoolWETHBalanceDiff,
            "balanceOf"
        );

        // TODO: assert that the reserve fee was paid in all successful tests.
        // TODO: assert that excess liquidity was re-added to the pair in relevant successful tests.
    }
}

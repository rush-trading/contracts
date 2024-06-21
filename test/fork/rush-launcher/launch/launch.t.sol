// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { Fork_Test } from "test/fork/Fork.t.sol";
import { RushLauncher } from "src/RushLauncher.sol";
import { RushERC20Basic } from "src/tokens/RushERC20Basic.sol";
import { FeeCalculator } from "src/FeeCalculator.sol";

// TODO: refactor to use Defaults rather than hardcoding values.
contract Launch_Fork_Test is Fork_Test {
    function setUp() public virtual override {
        Fork_Test.setUp();

        // Deposit liquidity to the pool.
        depositToLiquidityPool({ amount: defaults.DEPOSIT_AMOUNT() });

        // Add template to the factory.
        addTemplateToFactory({ implementation: address(new RushERC20Basic()) });
    }

    /// @dev Adds a template to the factory.
    // TODO: this is copied from Integration. Refactor to use a common function.
    function addTemplateToFactory(address implementation) internal {
        (, address caller,) = vm.readCallers();
        changePrank({ msgSender: users.admin });
        rushERC20Factory.addTemplate({ implementation: implementation });
        changePrank({ msgSender: caller });
    }

    function test_RevertWhen_TokenMaxSupplyIsLessThanMinimumLimit() external {
        // Run the test.
        uint256 maxSupply = defaults.TOKEN_MIN_SUPPLY() - 1;
        uint256 liquidityAmount = defaults.DISPATCH_AMOUNT();
        uint256 liquidityDuration = defaults.LIQUIDITY_DURATION();
        vm.expectRevert(abi.encodeWithSelector(Errors.RushLauncher_LowMaxSupply.selector, maxSupply));
        rushLauncher.launch(
            RushLauncher.LaunchParams({
                templateDescription: "RushERC20Basic",
                name: "MyToken",
                symbol: "MTK",
                maxSupply: maxSupply,
                data: abi.encodePacked(users.recipient, ""),
                liquidityAmount: liquidityAmount,
                liquidityDuration: liquidityDuration
            })
        );
    }

    function test_WhenTokenMaxSupplyIsGreaterOrEqualToMinimumLimit() external {
        uint256 maxSupply = defaults.TOKEN_MIN_SUPPLY();
        uint256 liquidityAmount = defaults.DISPATCH_AMOUNT();
        uint256 liquidityDuration = defaults.LIQUIDITY_DURATION();
        (uint256 fee,) = feeCalculator.calculateFee(
            FeeCalculator.CalculateFeeParams({
                duration: liquidityDuration,
                newLiquidity: liquidityAmount,
                outstandingLiquidity: liquidityPool.outstandingAssets(),
                reserveFactor: defaults.RESERVE_FACTOR(),
                totalLiquidity: liquidityPool.totalAssets()
            })
        );

        // Expect the relevant event to be emitted.
        vm.expectEmit({
            emitter: address(rushLauncher),
            checkTopic1: false, // Ignore `token` field.
            checkTopic2: true, // Check `kind` field.
            checkTopic3: false, // Ignore `pair` field.
            checkData: true // Check `maxSupply`, `liquidityAmount`, and `liquidityDuration` fields.
         });
        emit Launch({
            token: address(0),
            kind: keccak256(abi.encodePacked("RushERC20Basic")),
            pair: address(0),
            maxSupply: maxSupply,
            liquidityAmount: liquidityAmount,
            liquidityDuration: liquidityDuration
        });

        // Launch the token with pair and liquidity.
        rushLauncher.launch{ value: fee }(
            RushLauncher.LaunchParams({
                templateDescription: "RushERC20Basic",
                name: "MyToken",
                symbol: "MTK",
                maxSupply: maxSupply,
                data: abi.encodePacked(users.recipient, ""),
                liquidityAmount: liquidityAmount,
                liquidityDuration: liquidityDuration
            })
        );
    }
}

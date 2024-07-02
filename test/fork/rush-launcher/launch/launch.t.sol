// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { RushLauncher_Test } from "../RushLauncher.t.sol";
import { RushLauncher } from "src/RushLauncher.sol";
import { RushERC20Basic } from "src/tokens/RushERC20Basic.sol";
import { FeeCalculator } from "src/FeeCalculator.sol";

contract Launch_Fork_Test is RushLauncher_Test {
    function setUp() public virtual override {
        RushLauncher_Test.setUp();

        rushERC20 = new RushERC20Basic();

        // Deposit liquidity to the pool.
        deposit({ asset: address(weth), amount: defaults.DEPOSIT_AMOUNT() });

        // Add template to the factory.
        addTemplate({ implementation: address(rushERC20) });
    }

    function test_RevertWhen_TokenMaxSupplyIsLessThanMinimumLimit() external {
        // Run the test.
        uint256 maxSupply = defaults.RUSH_ERC20_MIN_SUPPLY() - 1;
        uint256 liquidityAmount = defaults.DISPATCH_AMOUNT();
        uint256 liquidityDuration = defaults.LIQUIDITY_DURATION();
        string memory description = rushERC20.description();
        vm.expectRevert(abi.encodeWithSelector(Errors.RushLauncher_LowMaxSupply.selector, maxSupply));
        rushLauncher.launch(
            RushLauncher.LaunchParams({
                templateDescription: description,
                name: "MyToken",
                symbol: "MTK",
                maxSupply: maxSupply,
                data: abi.encodePacked(users.recipient, ""),
                liquidityAmount: liquidityAmount,
                liquidityDuration: liquidityDuration
            })
        );
    }

    modifier whenTokenMaxSupplyIsNotLessThanMinimumLimit() {
        _;
    }

    function test_RevertWhen_TokenMaxSupplyIsGreaterThanMaximumLimit()
        external
        whenTokenMaxSupplyIsNotLessThanMinimumLimit
    {
        // Run the test.
        uint256 maxSupply = defaults.RUSH_ERC20_MAX_SUPPLY() + 1;
        uint256 liquidityAmount = defaults.DISPATCH_AMOUNT();
        uint256 liquidityDuration = defaults.LIQUIDITY_DURATION();
        string memory description = rushERC20.description();
        vm.expectRevert(abi.encodeWithSelector(Errors.RushLauncher_HighMaxSupply.selector, maxSupply));
        rushLauncher.launch(
            RushLauncher.LaunchParams({
                templateDescription: description,
                name: "MyToken",
                symbol: "MTK",
                maxSupply: maxSupply,
                data: abi.encodePacked(users.recipient, ""),
                liquidityAmount: liquidityAmount,
                liquidityDuration: liquidityDuration
            })
        );
    }

    function test_WhenTokenMaxSupplyIsNotGreaterThanMaximumLimit()
        external
        whenTokenMaxSupplyIsNotLessThanMinimumLimit
    {
        uint256 maxSupply = defaults.RUSH_ERC20_MAX_SUPPLY();
        uint256 liquidityAmount = defaults.DISPATCH_AMOUNT();
        uint256 liquidityDuration = defaults.LIQUIDITY_DURATION();
        string memory description = rushERC20.description();
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
            checkTopic1: false, // Ignore `rushERC20` field.
            checkTopic2: true, // Check `kind` field.
            checkTopic3: false, // Ignore `uniV2Pair` field.
            checkData: true // Check `maxSupply`, `liquidityAmount`, and `liquidityDuration` fields.
         });
        emit Launch({
            rushERC20: address(0),
            kind: keccak256(abi.encodePacked(description)),
            uniV2Pair: address(0),
            maxSupply: maxSupply,
            liquidityAmount: liquidityAmount,
            liquidityDuration: liquidityDuration
        });

        // Launch the RushERC20 token with its liquidity.
        rushLauncher.launch{ value: fee }(
            RushLauncher.LaunchParams({
                templateDescription: description,
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

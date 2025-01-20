// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { RushERC20Basic } from "src/tokens/RushERC20Basic.sol";
import { FC, RL } from "src/types/DataTypes.sol";
import { RushLauncher_Test } from "./../RushLauncher.t.sol";

contract Launch_Fork_Test is RushLauncher_Test {
    function setUp() public virtual override {
        RushLauncher_Test.setUp();

        rushERC20 = new RushERC20Basic();

        // Deposit liquidity to LiquidityPool.
        deposit({ asset: address(weth), amount: defaults.DEPOSIT_AMOUNT() });

        // Add template to RushERC20Factory.
        addTemplate({ implementation: address(rushERC20) });
    }

    function test_RevertWhen_CallerDoesNotHaveRouterRole() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        uint256 maxSupply = defaults.MAX_RUSH_ERC20_SUPPLY();
        uint256 liquidityAmount = defaults.LIQUIDITY_AMOUNT();
        uint256 liquidityDuration = defaults.LIQUIDITY_DURATION();
        bytes32 kind = keccak256(abi.encodePacked(rushERC20.description()));
        vm.expectRevert(abi.encodeWithSelector(Errors.OnlyRouterRole.selector, users.eve));
        rushLauncher.launch(
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
    }

    modifier whenCallerHasRouterRole() {
        resetPrank({ msgSender: users.router });
        _;
    }

    function test_RevertWhen_TokenMaxSupplyIsLessThanMinimumLimit() external whenCallerHasRouterRole {
        // Run the test.
        uint256 maxSupply = defaults.MIN_RUSH_ERC20_SUPPLY() - 1;
        uint256 liquidityAmount = defaults.LIQUIDITY_AMOUNT();
        uint256 liquidityDuration = defaults.LIQUIDITY_DURATION();
        bytes32 kind = keccak256(abi.encodePacked(rushERC20.description()));
        vm.expectRevert(abi.encodeWithSelector(Errors.RushLauncher_LowMaxSupply.selector, maxSupply));
        rushLauncher.launch(
            RL.LaunchParams({
                originator: users.sender,
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
    }

    modifier whenTokenMaxSupplyIsNotLessThanMinimumLimit() {
        _;
    }

    function test_RevertWhen_TokenMaxSupplyIsGreaterThanMaximumLimit()
        external
        whenCallerHasRouterRole
        whenTokenMaxSupplyIsNotLessThanMinimumLimit
    {
        // Run the test.
        uint256 maxSupply = defaults.MAX_RUSH_ERC20_SUPPLY() + 1;
        uint256 liquidityAmount = defaults.LIQUIDITY_AMOUNT();
        uint256 liquidityDuration = defaults.LIQUIDITY_DURATION();
        bytes32 kind = keccak256(abi.encodePacked(rushERC20.description()));
        vm.expectRevert(abi.encodeWithSelector(Errors.RushLauncher_HighMaxSupply.selector, maxSupply));
        rushLauncher.launch(
            RL.LaunchParams({
                originator: users.sender,
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
    }

    function test_WhenTokenMaxSupplyIsNotGreaterThanMaximumLimit()
        external
        whenCallerHasRouterRole
        whenTokenMaxSupplyIsNotLessThanMinimumLimit
    {
        uint256 maxSupply = defaults.MAX_RUSH_ERC20_SUPPLY();
        uint256 liquidityAmount = defaults.LIQUIDITY_AMOUNT();
        uint256 liquidityDuration = defaults.LIQUIDITY_DURATION();
        bytes32 kind = keccak256(abi.encodePacked(rushERC20.description()));
        (uint256 fee,) = feeCalculator.calculateFee(
            FC.CalculateFeeParams({
                duration: liquidityDuration,
                newLiquidity: liquidityAmount,
                outstandingLiquidity: liquidityPool.outstandingAssets(),
                reserveFactor: defaults.RESERVE_FACTOR(),
                totalLiquidity: liquidityPool.lastSnapshotTotalAssets()
            })
        );

        // Expect the relevant event to be emitted.
        vm.expectEmit({
            emitter: address(rushLauncher),
            checkTopic1: false, // Ignore `rushERC20` field.
            checkTopic2: true, // Check `kind` field.
            checkTopic3: true, // Check `originator` field.
            checkData: false // Ignor `uniV2Pair`, `maxSupply`, `liquidityAmount`, and `liquidityDuration` fields.
         });
        emit Launch({
            rushERC20: address(0),
            kind: kind,
            originator: users.sender,
            uniV2Pair: address(0),
            maxSupply: maxSupply,
            liquidityAmount: liquidityAmount,
            liquidityDuration: liquidityDuration
        });

        // Launch the RushERC20 token with its liquidity.
        rushLauncher.launch{ value: fee }(
            RL.LaunchParams({
                originator: users.sender,
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
    }
}

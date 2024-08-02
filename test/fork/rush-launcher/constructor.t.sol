// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { RushLauncher } from "src/RushLauncher.sol";

import { Fork_Test } from "test/fork/Fork.t.sol";

contract Constructor_RushLauncher_Fork_Test is Fork_Test {
    function test_Constructor() external {
        // Make Sender the caller in this test.
        resetPrank({ msgSender: users.sender });

        // Construct the contract.
        RushLauncher constructedRushLauncher = new RushLauncher({
            liquidityDeployer_: address(liquidityDeployer),
            maxSupplyLimit_: defaults.MAX_RUSH_ERC20_SUPPLY(),
            minSupplyLimit_: defaults.MIN_RUSH_ERC20_SUPPLY(),
            rushERC20Factory_: address(rushERC20Factory),
            uniswapV2Factory_: address(uniswapV2Factory)
        });

        // Assert that the values were set correctly.
        address actualERC20Factory = address(constructedRushLauncher.RUSH_ERC20_FACTORY());
        address expectedERC20Factory = address(rushERC20Factory);
        assertEq(address(actualERC20Factory), address(expectedERC20Factory), "ERC20_FACTORY");

        address actualLiquidityDeployer = constructedRushLauncher.LIQUIDITY_DEPLOYER();
        address expectedLiquidityDeployer = address(liquidityDeployer);
        assertEq(actualLiquidityDeployer, expectedLiquidityDeployer, "LIQUIDITY_DEPLOYER");

        uint256 actualMaxSupplyLimit = constructedRushLauncher.MAX_SUPPLY_LIMIT();
        uint256 expectedMaxSupplyLimit = defaults.MAX_RUSH_ERC20_SUPPLY();
        assertEq(actualMaxSupplyLimit, expectedMaxSupplyLimit, "MAX_SUPPLY_LIMIT");

        uint256 actualMinSupplyLimit = constructedRushLauncher.MIN_SUPPLY_LIMIT();
        uint256 expectedMinSupplyLimit = defaults.MIN_RUSH_ERC20_SUPPLY();
        assertEq(actualMinSupplyLimit, expectedMinSupplyLimit, "MIN_SUPPLY_LIMIT");

        address actualUniswapV2Factory = constructedRushLauncher.UNISWAP_V2_FACTORY();
        address expectedUniswapV2Factory = address(uniswapV2Factory);
        assertEq(actualUniswapV2Factory, expectedUniswapV2Factory, "UNISWAP_V2_FACTORY");
    }
}

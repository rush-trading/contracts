// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { IRushLauncher } from "src/interfaces/IRushLauncher.sol";
import { RushLauncher } from "src/RushLauncher.sol";
import { RushERC20Taxable } from "src/tokens/RushERC20Taxable.sol";
import { RL } from "src/types/DataTypes.sol";
import { Fork_Test } from "test/fork/Fork.t.sol";

// TODO: refactor to apply repo test style
contract LauncherPoolInteraction is Fork_Test {
    address exchangePool;
    IRushLauncher rushLauncher;

    function setUp() public virtual override {
        Fork_Test.setUp();
        deploy();
    }

    function deploy() internal {
        address implementation = address(new RushERC20Taxable());

        addTemplate({ implementation: implementation });
        rushERC20 = RushERC20Taxable(createRushERC20({ implementation: implementation }));
        deployLauncher();
    }

    function deployLauncher() internal {
        rushLauncher = IRushLauncher(
            new RushLauncher({
                aclManager_: address(aclManager),
                liquidityDeployer_: address(liquidityDeployer),
                maxSupplyLimit_: defaults.MAX_RUSH_ERC20_SUPPLY(),
                minSupplyLimit_: defaults.MIN_RUSH_ERC20_SUPPLY(),
                rushERC20Factory_: address(rushERC20Factory),
                uniswapV2Factory_: address(uniswapV2Factory)
            })
        );
        vm.label({ account: address(rushLauncher), newLabel: "RushLauncher" });
        resetPrank({ msgSender: users.admin });
        aclManager.addLauncher({ account: address(rushLauncher) });
    }

    function test_launch() public {
        resetPrank(users.launcher);
        bytes32 _kind = 0xfa3f84d263ed55bc45f8e22cdb3a7481292f68ee28ab539b69876f8dc1535b40;
        address _owner = address(2);
        bytes memory _data = abi.encode(_owner, address(liquidityDeployer), defaults.RUSH_ERC20_TAX_BPS());
        deposit(address(weth), 10 ether);
        RL.LaunchParams memory launchParams = RL.LaunchParams(
            msg.sender, _kind, "TestTaxToken", "TTT", defaults.RUSH_ERC20_SUPPLY(), _data, 1 ether, 1000
        );

        resetPrank(users.router);
        (address tokenAddy, address _exchangePool) = rushLauncher.launch{ value: 0.1 ether }(launchParams);
        exchangePool = _exchangePool;
        rushERC20 = RushERC20Taxable(tokenAddy);
        uint256 taxBeneficiaryPreBalance = rushERC20.balanceOf(_owner);

        vm.warp(block.timestamp + 10_000);
        liquidityDeployer.unwindLiquidity(exchangePool);
        uint256 taxBeneficiaryPostBalance = rushERC20.balanceOf(_owner);

        assertEq(taxBeneficiaryPreBalance, taxBeneficiaryPostBalance);
    }
}

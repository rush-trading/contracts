// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Test } from "forge-std/src/Test.sol";
import { Users } from "./utils/Types.sol";
import { Utils } from "./utils/Utils.sol";
import { Calculations } from "./utils/Calculations.sol";
import { Constants } from "./utils/Constants.sol";
import { Defaults } from "./utils/Defaults.sol";
import { Events } from "./utils/Events.sol";

import { IRushERC20 } from "src/interfaces/IRushERC20.sol";
import { FeeCalculator } from "src/FeeCalculator.sol";
import { LiquidityDeployerWETH } from "src/LiquidityDeployerWETH.sol";
import { LiquidityPool } from "src/LiquidityPool.sol";
import { RushERC20Factory } from "src/RushERC20Factory.sol";
import { WETHMock } from "test/mocks/WethMock.sol";

/// @notice Base test contract with common logic needed by all tests.
abstract contract Base_Test is Test, Utils, Calculations, Constants, Events {
    // #region ----------------------------------=|+ VARIABLES +|=----------------------------------- //

    Users internal users;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    Defaults internal defaults;
    // TODO: Use interfaces instead of concrete contracts.
    FeeCalculator internal feeCalculator;
    LiquidityDeployerWETH internal liquidityDeployerWETH;
    LiquidityPool internal liquidityPool;
    IRushERC20 internal rushERC20;
    RushERC20Factory internal rushERC20Factory;
    WETHMock internal wethMock;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ SET-UP FUNCTION +|=------------------------------- //

    function setUp() public virtual {
        // Deploy the base test contracts.
        wethMock = new WETHMock();

        // Create users for testing.
        users = Users({
            admin: createUser("Admin"),
            eve: createUser("Eve"),
            liquidityDeployer: createUser("LiquidityDeployer"),
            recipient: createUser("Recipient"),
            reserve: createUser("Reserve"),
            sender: createUser("Sender"),
            tokenDeployer: createUser("TokenDeployer")
        });

        // Deploy the defaults contract.
        defaults = new Defaults();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Adds a template to the factory.
    function addTemplateToFactory(address implementation) internal {
        (, address caller,) = vm.readCallers();
        changePrank({ msgSender: users.admin });
        rushERC20Factory.addTemplate({ implementation: implementation });
        changePrank({ msgSender: caller });
    }

    /// @dev Approves the core contracts to spend assets from the users.
    function approveCore() internal {
        (, address caller,) = vm.readCallers();
        changePrank({ msgSender: users.sender });
        wethMock.approve({ spender: address(liquidityPool), value: type(uint256).max });
        changePrank({ msgSender: caller });
    }

    /// @dev Creates a RushERC20 token.
    function createRushERC20(address implementation) internal returns (address) {
        (, address caller,) = vm.readCallers();
        changePrank({ msgSender: users.admin });
        rushERC20Factory.addTemplate({ implementation: implementation });
        changePrank({ msgSender: users.tokenDeployer });
        address erc20 = rushERC20Factory.createERC20({
            originator: users.sender,
            kind: keccak256(abi.encodePacked(IRushERC20(implementation).description()))
        });
        changePrank({ msgSender: caller });
        return erc20;
    }

    /// @dev Generates a user, labels its address, and funds it with test assets.
    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        deal({ token: address(wethMock), to: user, give: 100 ether });
        return user;
    }

    /// @dev Deposits assets from the Sender to the liquidity pool.
    function depositToLiquidityPool(uint256 amount) internal {
        (, address caller,) = vm.readCallers();
        changePrank({ msgSender: users.sender });
        liquidityPool.deposit({ assets: amount, receiver: users.sender });
        changePrank({ msgSender: caller });
    }

    /// @dev Deploys the core contracts.
    function deployCore() internal {
        rushERC20Factory = new RushERC20Factory({ admin_: users.admin });
        vm.label({ account: address(rushERC20Factory), newLabel: "RushERC20Factory" });
        liquidityPool = new LiquidityPool({ admin_: users.admin, asset_: address(wethMock) });
        vm.label({ account: address(liquidityPool), newLabel: "LiquidityPool" });
        feeCalculator = new FeeCalculator({
            baseFeeRate: defaults.BASE_FEE_RATE(),
            optimalUtilizationRatio: defaults.OPTIMAL_UTILIZATION_RATIO(),
            rateSlope1: defaults.RATE_SLOPE1(),
            rateSlope2: defaults.RATE_SLOPE2()
        });
        vm.label({ account: address(feeCalculator), newLabel: "FeeCalculator" });
        liquidityDeployerWETH = new LiquidityDeployerWETH({
            admin_: users.admin,
            earlyUnwindThreshold_: defaults.EARLY_UNWIND_THRESHOLD(),
            feeCalculator_: address(feeCalculator),
            liquidityPool_: address(liquidityPool),
            maxDeploymentAmount_: defaults.MAX_LIQUIDITY_AMOUNT(),
            maxDuration_: defaults.MAX_LIQUIDITY_DURATION(),
            minDeploymentAmount_: defaults.MIN_LIQUIDITY_AMOUNT(),
            minDuration_: defaults.MIN_LIQUIDITY_DURATION(),
            reserve_: users.reserve,
            reserveFactor_: defaults.RESERVE_FACTOR()
        });
        vm.label({ account: address(liquidityDeployerWETH), newLabel: "LiquidityDeployerWETH" });
    }

    /// @dev Grants the necessary roles of the core contracts.
    function grantRolesCore() internal {
        (, address caller,) = vm.readCallers();
        changePrank({ msgSender: users.admin });
        liquidityPool.grantRole({ role: ASSET_MANAGER_ROLE, account: address(liquidityDeployerWETH) });
        rushERC20Factory.grantRole({ role: TOKEN_DEPLOYER_ROLE, account: address(users.tokenDeployer) });
        liquidityDeployerWETH.grantRole({ role: LIQUIDITY_DEPLOYER_ROLE, account: address(users.liquidityDeployer) });
        changePrank({ msgSender: caller });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

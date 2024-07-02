// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Test } from "forge-std/src/Test.sol";
import { Users } from "./utils/Types.sol";
import { Utils } from "./utils/Utils.sol";
import { Calculations } from "./utils/Calculations.sol";
import { Constants } from "./utils/Constants.sol";
import { Defaults } from "./utils/Defaults.sol";
import { Events } from "./utils/Events.sol";
import { Precompiles } from "./utils/Precompiles.sol";

import { IRushERC20 } from "src/interfaces/IRushERC20.sol";
import { FeeCalculator } from "src/FeeCalculator.sol";
import { LiquidityDeployer } from "src/LiquidityDeployer.sol";
import { LiquidityPool } from "src/LiquidityPool.sol";
import { RushERC20Factory } from "src/RushERC20Factory.sol";
import { WETHMock } from "test/mocks/WethMock.sol";

/// @notice Base test contract with common logic needed by all tests.
abstract contract Base_Test is Test, Utils, Calculations, Constants, Events, Precompiles {
    // #region ----------------------------------=|+ VARIABLES +|=----------------------------------- //

    Users internal users;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    Defaults internal defaults;
    // TODO: Use interfaces instead of concrete contracts.
    FeeCalculator internal feeCalculator;
    LiquidityDeployer internal liquidityDeployer;
    LiquidityPool internal liquidityPool;
    IRushERC20 internal rushERC20;
    RushERC20Factory internal rushERC20Factory;
    WETHMock internal wethMock;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ SET-UP FUNCTION +|=------------------------------- //

    function setUp() public virtual {
        // Deploy the base test contracts.
        wethMock = new WETHMock();

        // Label the base test contracts.
        vm.label({ account: address(wethMock), newLabel: "WETHMock" });

        // Create users for testing.
        users = Users({
            admin: createUser("Admin"),
            eve: createUser("Eve"),
            liquidityDeployer: createUser("LiquidityDeployer"),
            recipient: createUser("Recipient"),
            reserve: createUser("Reserve"),
            rushCreator: createUser("RushCreator"),
            sender: createUser("Sender")
        });

        // Deploy the defaults contract.
        defaults = new Defaults();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Adds a template to the RushERC20Factory.
    function addTemplate(address implementation) internal {
        (, address caller,) = vm.readCallers();
        resetPrank({ msgSender: users.admin });
        rushERC20Factory.addTemplate({ implementation: implementation });
        resetPrank({ msgSender: caller });
    }

    /// @dev Creates a RushERC20 token.
    function createRushERC20(address implementation) internal returns (address) {
        (, address caller,) = vm.readCallers();
        resetPrank({ msgSender: users.admin });
        rushERC20Factory.addTemplate({ implementation: implementation });
        resetPrank({ msgSender: users.rushCreator });
        address erc20 = rushERC20Factory.createRushERC20({
            originator: users.sender,
            kind: keccak256(abi.encodePacked(IRushERC20(implementation).description()))
        });
        resetPrank({ msgSender: caller });
        return erc20;
    }

    /// @dev Generates a user, labels its address, and funds it with test assets.
    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.label({ account: user, newLabel: name });
        vm.deal({ account: user, newBalance: 100 ether });
        return user;
    }

    /// @dev Deploys the core contracts.
    function deployCore() internal {
        rushERC20Factory = new RushERC20Factory({ admin_: users.admin });
        vm.label({ account: address(rushERC20Factory), newLabel: "RushERC20Factory" });
        feeCalculator = new FeeCalculator({
            baseFeeRate: defaults.BASE_FEE_RATE(),
            optimalUtilizationRatio: defaults.OPTIMAL_UTILIZATION_RATIO(),
            rateSlope1: defaults.RATE_SLOPE1(),
            rateSlope2: defaults.RATE_SLOPE2()
        });
        vm.label({ account: address(feeCalculator), newLabel: "FeeCalculator" });
        liquidityDeployer = new LiquidityDeployer({
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
        vm.label({ account: address(liquidityDeployer), newLabel: "LiquidityDeployer" });
    }

    /// @dev Deposits assets from the Sender to the LiquidityPool.
    function deposit(address asset, uint256 amount) internal {
        (, address caller,) = vm.readCallers();
        resetPrank({ msgSender: users.sender });
        deal({ token: asset, to: users.sender, give: amount });
        IERC20(asset).approve({ spender: address(liquidityPool), value: amount });
        liquidityPool.deposit({ assets: amount, receiver: users.sender });
        resetPrank({ msgSender: caller });
    }

    /// @dev Grants the necessary roles of the core contracts.
    function grantRolesCore() internal {
        (, address caller,) = vm.readCallers();
        resetPrank({ msgSender: users.admin });
        liquidityPool.grantRole({ role: ASSET_MANAGER_ROLE, account: address(liquidityDeployer) });
        rushERC20Factory.grantRole({ role: RUSH_CREATOR_ROLE, account: address(users.rushCreator) });
        liquidityDeployer.grantRole({ role: LIQUIDITY_DEPLOYER_ROLE, account: address(users.liquidityDeployer) });
        resetPrank({ msgSender: caller });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

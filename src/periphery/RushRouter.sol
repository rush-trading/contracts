// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ILiquidityDeployer } from "src/interfaces/ILiquidityDeployer.sol";
import { ILiquidityPool } from "src/interfaces/ILiquidityPool.sol";
import { IRushLauncher } from "src/interfaces/IRushLauncher.sol";
import { IWETH } from "src/external/IWETH.sol";

import { RL } from "src/types/DataTypes.sol";

/**
 * @title RushRouter
 * @notice A periphery contract that acts as a DSProxy target for Rush protocol interactions.
 */
contract RushRouter {
    using SafeERC20 for IERC20;

    // #region ----------------------------------=|+ CONSTANTS +|=----------------------------------- //

    /// @dev The RushERC20Basic kind.
    bytes32 internal constant RUSH_ERC20_BASIC_KIND = 0xcac1368504ad87313cdd2f6dcf30ca9b9464d5bcb5a8a0613bbe9dce5b33a365;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ IMMUTABLES +|=---------------------------------- //

    /// @notice The address of the LiquidityDeployer contract.
    ILiquidityDeployer public immutable LIQUIDITY_DEPLOYER;

    /// @notice The address of the LiquidityPool contract.
    ILiquidityPool public immutable LIQUIDITY_POOL;

    /// @notice The address of the RushLauncher contract.
    IRushLauncher public immutable RUSH_LAUNCHER;

    /// @notice The WETH address.
    address public immutable WETH;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    /**
     * @dev Constructor
     * @param rushLauncher_ The address of the RushLauncher contract.
     */
    constructor(IRushLauncher rushLauncher_) {
        RUSH_LAUNCHER = rushLauncher_;
        LIQUIDITY_DEPLOYER = ILiquidityDeployer(rushLauncher_.LIQUIDITY_DEPLOYER());
        LIQUIDITY_POOL = ILiquidityPool(LIQUIDITY_DEPLOYER.LIQUIDITY_POOL());
        WETH = LIQUIDITY_DEPLOYER.WETH();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /**
     * @notice Launch an ERC20 token.
     * @param name The name of the launched ERC20 token.
     * @param symbol The symbol of the launched ERC20 token.
     * @param maxSupply The maximum supply of the launched ERC20 token.
     * @param liquidityAmount The amount of WETH liquidity to deploy.
     * @param liquidityDuration The duration of the liquidity deployment.
     */
    function launchERC20(
        string calldata name,
        string calldata symbol,
        uint256 maxSupply,
        uint256 liquidityAmount,
        uint256 liquidityDuration
    )
        external
        payable
    {
        // Launch the ERC20 token.
        RUSH_LAUNCHER.launch{ value: msg.value }(
            RL.LaunchParams({
                kind: RUSH_ERC20_BASIC_KIND,
                name: name,
                symbol: symbol,
                maxSupply: maxSupply,
                data: "",
                liquidityAmount: liquidityAmount,
                liquidityDuration: liquidityDuration
            })
        );
    }

    /**
     * @notice Lend WETH to the LiquidityPool.
     * @param amount The amount of WETH to lend.
     */
    function lend(uint256 amount) external {
        // Transfer the amount of WETH to this contract.
        IERC20(WETH).safeTransferFrom({ from: msg.sender, to: address(this), value: amount });

        // Approve the LiquidityPool to spend the WETH.
        IERC20(WETH).approve({ spender: address(LIQUIDITY_POOL), value: amount });

        // Deposit the WETH into the LiquidityPool and mint the corresponding amount of shares to the sender.
        LIQUIDITY_POOL.deposit({ assets: amount, receiver: msg.sender });
    }

    /**
     * @notice Lend ETH to the LiquidityPool.
     */
    function lendETH() external payable {
        // Deposit the ETH into WETH.
        IWETH(WETH).deposit{ value: msg.value }();

        // Approve the LiquidityPool to spend the WETH.
        IERC20(WETH).approve({ spender: address(LIQUIDITY_POOL), value: msg.value });

        // Deposit the WETH into the LiquidityPool and mint the corresponding amount of shares to the sender.
        LIQUIDITY_POOL.deposit({ assets: msg.value, receiver: msg.sender });
    }

    /**
     * @notice Withdraw lent WETH from the LiquidityPool.
     * @param amount The amount of WETH to withdraw.
     */
    function withdraw(uint256 amount) external {
        // Calculate the amount of shares to redeem.
        uint256 shares = LIQUIDITY_POOL.previewWithdraw(amount);

        // Transfer the amount of shares to this contract.
        IERC20(LIQUIDITY_POOL).safeTransferFrom({ from: msg.sender, to: address(this), value: shares });

        // Redeem the amount of shares from the LiquidityPool and transfer the corresponding amount of WETH to the
        // sender.
        LIQUIDITY_POOL.redeem({ shares: shares, receiver: msg.sender, owner: address(this) });
    }

    /**
     * @notice Withdraw lent ETH from the LiquidityPool.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawETH(uint256 amount) external {
        // Calculate the amount of shares to redeem.
        uint256 shares = LIQUIDITY_POOL.previewWithdraw(amount);

        // Transfer the amount of shares to this contract.
        IERC20(LIQUIDITY_POOL).safeTransferFrom({ from: msg.sender, to: address(this), value: shares });

        // Redeem the amount of shares from the LiquidityPool and transfer the corresponding amount of WETH to this
        // contract.
        uint256 received = LIQUIDITY_POOL.redeem({ shares: shares, receiver: address(this), owner: address(this) });

        // Withdraw the received WETH to ETH.
        IWETH(WETH).withdraw(received);

        // Transfer the amount of WETH to the sender.
        payable(msg.sender).transfer(received);
    }

    /**
     * @notice Unwind deployed liquidity after the liquidity duration has expired.
     * @param uniV2Pair The address of the Uniswap V2 pair to unwind.
     */
    function unwindLiquidity(address uniV2Pair) external {
        // Unwind the liquidity deployment.
        LIQUIDITY_DEPLOYER.unwindLiquidity({ uniV2Pair: uniV2Pair });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

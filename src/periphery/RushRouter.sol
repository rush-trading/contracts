// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IWETH } from "src/external/IWETH.sol";
import { ILiquidityDeployer } from "src/interfaces/ILiquidityDeployer.sol";
import { ILiquidityPool } from "src/interfaces/ILiquidityPool.sol";
import { IRushLauncher } from "src/interfaces/IRushLauncher.sol";
import { RL } from "src/types/DataTypes.sol";

/**
 * @title RushRouter
 * @notice A periphery contract that acts as a router for Rush protocol operations.
 */
contract RushRouter {
    // #region ----------------------------------=|+ CONSTANTS +|=----------------------------------- //

    /// @dev The RushERC20Basic kind (i.e., keccak256("RushERC20Basic")).
    bytes32 internal constant RUSH_ERC20_BASIC_KIND = 0xcac1368504ad87313cdd2f6dcf30ca9b9464d5bcb5a8a0613bbe9dce5b33a365;

    /// @dev The RushERC20Taxable kind (i.e., keccak256("RushERC20Taxable")).
    bytes32 internal constant RUSH_ERC20_TAXABLE_KIND =
        0xfa3f84d263ed55bc45f8e22cdb3a7481292f68ee28ab539b69876f8dc1535b40;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------------=|+ ENUMS +|=------------------------------------- //

    /// @dev The tax tier of a taxable ERC20 token.
    enum TaxTier {
        Small,
        Medium,
        Large
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------------=|+ ERRORS +|=------------------------------------ //

    /// @dev Thrown when the minimum shares out is not met.
    error RushRouter_MinSharesError();

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

    // #region ------------------------------=|+ FALLBACK FUNCTIONS +|=------------------------------ //

    receive() external payable {
        // Only accept ETH via fallback from the WETH contract.
        assert(msg.sender == WETH);
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------=|+ USER-FACING NON-CONSTANT FUNCTIONS +|=---------------------- //

    /**
     * @notice Launch an ERC20 token.
     * @param name The name of the launched ERC20 token.
     * @param symbol The symbol of the launched ERC20 token.
     * @param maxSupply The maximum supply of the launched ERC20 token.
     * @param liquidityAmount The amount of WETH liquidity to deploy.
     * @param liquidityDuration The duration of the liquidity deployment.
     * @param maxTotalFee The maximum total fee that can be collected for the liquidity deployment.
     */
    function launchERC20(
        string calldata name,
        string calldata symbol,
        uint256 maxSupply,
        uint256 liquidityAmount,
        uint256 liquidityDuration,
        uint256 maxTotalFee
    )
        external
        payable
    {
        // Launch the ERC20 token.
        RUSH_LAUNCHER.launch{ value: msg.value }(
            RL.LaunchParams({
                originator: msg.sender,
                kind: RUSH_ERC20_BASIC_KIND,
                name: name,
                symbol: symbol,
                maxSupply: maxSupply,
                data: "",
                liquidityAmount: liquidityAmount,
                liquidityDuration: liquidityDuration,
                maxTotalFee: maxTotalFee
            })
        );
    }

    /**
     * @notice Launch a taxable ERC20 token.
     * @param name The name of the launched ERC20 token.
     * @param symbol The symbol of the launched ERC20 token.
     * @param maxSupply The maximum supply of the launched ERC20 token.
     * @param taxTier The tax tier of the launched ERC20 token.
     * @param liquidityAmount The amount of WETH liquidity to deploy.
     * @param liquidityDuration The duration of the liquidity deployment.
     * @param maxTotalFee The maximum total fee that can be collected for the liquidity deployment.
     */
    function launchERC20Taxable(
        string calldata name,
        string calldata symbol,
        uint256 maxSupply,
        TaxTier taxTier,
        uint256 liquidityAmount,
        uint256 liquidityDuration,
        uint256 maxTotalFee
    )
        external
        payable
    {
        // Launch the ERC20 token.
        RUSH_LAUNCHER.launch{ value: msg.value }(
            RL.LaunchParams({
                originator: msg.sender,
                kind: RUSH_ERC20_TAXABLE_KIND,
                name: name,
                symbol: symbol,
                maxSupply: maxSupply,
                data: abi.encode(
                    msg.sender,
                    address(LIQUIDITY_DEPLOYER),
                    taxTier == TaxTier.Small ? 100 : taxTier == TaxTier.Medium ? 300 : 500
                ),
                liquidityAmount: liquidityAmount,
                liquidityDuration: liquidityDuration,
                maxTotalFee: maxTotalFee
            })
        );
    }

    /**
     * @notice Lend WETH to the LiquidityPool.
     * @param amount The amount of WETH to lend.
     */
    function lend(uint256 amount, uint256 minSharesOut) external returns (uint256 sharesOut) {
        // Transfer the amount of WETH to this contract.
        IERC20(WETH).transferFrom({ from: msg.sender, to: address(this), value: amount });

        // Approve the LiquidityPool to spend the WETH.
        IERC20(WETH).approve({ spender: address(LIQUIDITY_POOL), value: amount });

        // Deposit the WETH into the LiquidityPool and mint the corresponding amount of shares to the sender.
        if ((sharesOut = LIQUIDITY_POOL.deposit({ assets: amount, receiver: msg.sender })) < minSharesOut) {
            revert RushRouter_MinSharesError();
        }
    }

    /**
     * @notice Lend ETH to the LiquidityPool.
     */
    function lendETH(uint256 minSharesOut) external payable returns (uint256 sharesOut) {
        // Deposit the ETH into WETH.
        IWETH(WETH).deposit{ value: msg.value }();

        // Approve the LiquidityPool to spend the WETH.
        IERC20(WETH).approve({ spender: address(LIQUIDITY_POOL), value: msg.value });

        // Deposit the WETH into the LiquidityPool and mint the corresponding amount of shares to the sender.
        if ((sharesOut = LIQUIDITY_POOL.deposit({ assets: msg.value, receiver: msg.sender })) < minSharesOut) {
            revert RushRouter_MinSharesError();
        }
    }

    /**
     * @notice Withdraw lent WETH from the LiquidityPool.
     * @param amount The amount of WETH to withdraw.
     */
    function withdraw(uint256 amount) external {
        // Calculate the amount of shares to redeem.
        uint256 shares = LIQUIDITY_POOL.previewWithdraw(amount);

        // Transfer the amount of shares to this contract.
        IERC20(LIQUIDITY_POOL).transferFrom({ from: msg.sender, to: address(this), value: shares });

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
        IERC20(LIQUIDITY_POOL).transferFrom({ from: msg.sender, to: address(this), value: shares });

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

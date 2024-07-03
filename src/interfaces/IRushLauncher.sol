// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { IUniswapV2Factory } from "src/external/IUniswapV2Factory.sol";
import { IRushERC20Factory } from "src/RushERC20Factory.sol";
import { RL } from "src/types/DataTypes.sol";

/**
 * @title IRushLauncher
 * @notice A permission-less contract for launching ERC20 token markets.
 */
interface IRushLauncher {
    // #region ------------------------------------=|+ EVENTS +|=------------------------------------ //

    /**
     * @notice Emitted when a new ERC20 token market is launched.
     * @param rushERC20 The address of the RushERC20 token.
     * @param kind The kind of the ERC20 token template.
     * @param uniV2Pair The address of the Uniswap V2 pair.
     * @param maxSupply The minted maximum supply of the ERC20 token.
     * @param liquidityAmount The amount of base asset liquidity deployed.
     * @param liquidityDuration The duration of the liquidity deployment.
     */
    event Launch(
        address indexed rushERC20,
        bytes32 indexed kind,
        address indexed uniV2Pair,
        uint256 maxSupply,
        uint256 liquidityAmount,
        uint256 liquidityDuration
    );

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /// @notice The address of the base asset for liquidity.
    function BASE_ASSET() external view returns (address);

    /// @notice The address of the LiquidityDeployer.
    function LIQUIDITY_DEPLOYER() external view returns (address);

    /// @notice The maximum minted supply of the ERC20 token.
    function MAX_SUPPLY_LIMIT() external view returns (uint256);

    /// @notice The minimum minted supply of the ERC20 token.
    function MIN_SUPPLY_LIMIT() external view returns (uint256);

    /// @notice The address of the RushERC20Factory.
    function RUSH_ERC20_FACTORY() external view returns (address);

    /// @notice The address of the Uniswap V2 factory.
    function UNISWAP_V2_FACTORY() external view returns (address);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------=|+ NON-CONSTANT FUNCTIONS +|=---------------------------- //

    /**
     * @notice Launches a new ERC20 token market.
     * @param params The launch parameters.
     */
    function launch(RL.LaunchParams calldata params) external payable returns (address rushERC20, address uniV2Pair);

    // #endregion ----------------------------------------------------------------------------------- //
}

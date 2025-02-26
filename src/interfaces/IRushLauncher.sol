// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import { IACLRoles } from "src/interfaces/IACLRoles.sol";
import { RL } from "src/types/DataTypes.sol";

/**
 * @title IRushLauncher
 * @notice A permissioned contract for launching ERC20 token markets.
 */
interface IRushLauncher is IACLRoles {
    // #region ------------------------------------=|+ EVENTS +|=------------------------------------ //

    /**
     * @notice Emitted when a new ERC20 token market is launched.
     * @param rushERC20 The address of the RushERC20 token.
     * @param kind The kind of the ERC20 token template.
     * @param originator The address that originated the request (i.e., the user).
     * @param uniV2Pair The address of the Uniswap V2 pair.
     * @param maxSupply The maximum supply of the ERC20 token.
     * @param liquidityAmount The amount of base asset liquidity deployed.
     * @param liquidityDuration The duration of the liquidity deployment.
     */
    event Launch(
        address indexed rushERC20,
        bytes32 indexed kind,
        address indexed originator,
        address uniV2Pair,
        uint256 maxSupply,
        uint256 liquidityAmount,
        uint256 liquidityDuration
    );

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ CONSTANT FUNCTIONS +|=------------------------------ //

    /// @notice The address of the LiquidityDeployer.
    function LIQUIDITY_DEPLOYER() external view returns (address);

    /// @notice The maximum supply limit of the ERC20 token.
    function MAX_SUPPLY_LIMIT() external view returns (uint256);

    /// @notice The minimum supply limit of the ERC20 token.
    function MIN_SUPPLY_LIMIT() external view returns (uint256);

    /// @notice The address of the RushERC20Factory.
    function RUSH_ERC20_FACTORY() external view returns (address);

    /// @notice The address of the Uniswap V2 factory.
    function UNISWAP_V2_FACTORY() external view returns (address);

    /// @notice The WETH contract address.
    /// @dev WETH is used as the base asset for liquidity deployment.
    function WETH() external view returns (address);

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------=|+ NON-CONSTANT FUNCTIONS +|=---------------------------- //

    /**
     * @notice Launches a new ERC20 token market.
     * @param params The launch parameters.
     * @return rushERC20 The address of the RushERC20 token launched.
     * @return uniV2Pair The address of the Uniswap V2 pair created for the market.
     */
    function launch(RL.LaunchParams calldata params) external payable returns (address rushERC20, address uniV2Pair);

    // #endregion ----------------------------------------------------------------------------------- //
}

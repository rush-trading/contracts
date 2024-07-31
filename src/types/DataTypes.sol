// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

/// @notice Namespace for the structs used in {FeeCalculator}.
library FC {
    /// @dev The local variables used in `calculateFee`.
    struct CalculateFeeLocalVars {
        uint256 feeRate;
        uint256 utilizationRatio;
    }

    /**
     * @dev The parameters to calculate the liquidity deployment fee.
     * @param duration The duration of liquidity deployment (in seconds).
     * @param newLiquidity The liquidity to be deployed.
     * @param outstandingLiquidity The liquidity already deployed.
     * @param reserveFactor The reserve factor.
     * @param totalLiquidity The total liquidity managed by LiquidityPool.
     */
    struct CalculateFeeParams {
        uint256 duration;
        uint256 newLiquidity;
        uint256 outstandingLiquidity;
        uint256 reserveFactor;
        uint256 totalLiquidity;
    }
}

/// @notice Namespace for the structs used in {LiquidityDeployer}.
library LD {
    /// @dev The local variables used in `deployLiquidity`.
    struct DeployLiquidityLocalVars {
        uint256 rushERC20BalanceOfPair;
        uint256 rushERC20TotalSupply;
        uint256 reserveFee;
        uint256 totalFee;
        uint256 deadline;
        uint256 excessValue;
        bool isToken0WETH;
        uint256 reserve0;
        uint256 reserve1;
        uint256 wethReserve;
        uint256 rushERC20Reserve;
        uint256 amountWETHInWithFee;
        uint256 numerator;
        uint256 denominator;
        uint256 maxAmountRushERC20Out;
    }

    /**
     * @dev The liquidity deployment entity.
     * @param amount The amount of base asset liquidity deployed.
     * @param deadline The deadline timestamp by which the liquidity must be unwound.
     * @param isUnwound A flag indicating whether the liquidity has been unwound.
     * @param subsidyAmount The amount of base asset liquidity subsidized by the protocol.
     * @param rushERC20 The address of the RushERC20 token.
     * @param originator The address that originated the request (i.e., the user).
     */
    struct LiquidityDeployment {
        uint208 amount; // ─┐
        uint40 deadline; // │
        bool isUnwound; // ─┘
        uint96 subsidyAmount; // ─┐
        address rushERC20; // ────┘
        address originator;
    }

    /// @dev The local variables used in `onReturnAsset`.
    struct OnReturnAssetLocalVars {
        address uniV2Pair;
        address rushERC20;
        uint256 wethSubsidy;
        uint256 wethBalance;
        uint256 rushERC20Balance;
        uint256 initialWETHReserve;
        uint256 wethSurplus;
        uint256 wethSurplusTax;
        uint256 totalReserveFee;
        uint256 wethToLock;
        uint256 rushERC20ToLock;
    }
}

/// @notice Namespace for the structs used in {RushLauncher}.
library RL {
    /**
     * @dev The parameters for launching a new ERC20 token market.
     * @param kind The kind of the ERC20 token template.
     * @param name The name of the ERC20 token.
     * @param symbol The symbol of the ERC20 token.
     * @param maxSupply The minted maximum supply of the ERC20 token.
     * @param data Additional data for the token initialization.
     * @param liquidityAmount The amount of base asset liquidity to deploy.
     * @param liquidityDuration The duration of the liquidity deployment (in seconds).
     */
    struct LaunchParams {
        bytes32 kind;
        string name;
        string symbol;
        uint256 maxSupply;
        bytes data;
        uint256 liquidityAmount;
        uint256 liquidityDuration;
    }
}

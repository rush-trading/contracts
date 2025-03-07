// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

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
    /**
     * @dev The parameters for constructing a new LiquidityDeployer.
     * @param aclManager_ The address of the ACLManager contract.
     * @param earlyUnwindThreshold_ The level of asset liquidity in pair at which early unwinding is allowed.
     * @param feeCalculator_ The address of the FeeCalculator contract.
     * @param liquidityPool_ The address of the LiquidityPool contract.
     * @param maxDeploymentAmount_ The maximum amount that can be deployed as liquidity.
     * @param maxDuration_ The maximum duration for liquidity deployment.
     * @param minDeploymentAmount_ The minimum amount that can be deployed as liquidity.
     * @param minDuration_ The minimum duration for liquidity deployment.
     * @param reserve_ The address of the reserve to which collected fees are sent.
     * @param reserveFactor_ The reserve factor for collected fees.
     * @param rewardFactor_ The reward factor for successful liquidity deployments.
     * @param rushSmartLock_ The address of the RushSmartLock contract.
     * @param surplusFactor_ The surplus factor for calculating WETH surplus tax.
     */
    struct ConstructorParam {
        address aclManager_;
        uint256 earlyUnwindThreshold_;
        address feeCalculator_;
        address liquidityPool_;
        uint256 maxDeploymentAmount_;
        uint256 maxDuration_;
        uint256 minDeploymentAmount_;
        uint256 minDuration_;
        address reserve_;
        uint256 reserveFactor_;
        uint256 rewardFactor_;
        address rushSmartLock_;
        uint256 surplusFactor_;
    }

    /// @dev The local variables used in `deployLiquidity`.
    struct DeployLiquidityLocalVars {
        uint256 rushERC20BalanceOfPair;
        uint256 rushERC20TotalSupply;
        uint256 reserveFee;
        uint256 totalFee;
        uint256 deadline;
        uint256 excessValue;
    }

    /**
     * @dev The liquidity deployment entity.
     * @param amount The amount of base asset liquidity deployed.
     * @param deadline The deadline timestamp by which the liquidity must be unwound.
     * @param isUnwound A flag indicating whether the liquidity has been unwound.
     * @param isUnwindThresholdMet A flag indicating whether the unwind threshold has been met.
     * @param subsidyAmount The amount of base asset liquidity subsidized by the protocol.
     * @param rushERC20 The address of the RushERC20 token.
     * @param originator The address that originated the request (i.e., the user).
     */
    struct LiquidityDeployment {
        uint208 amount; // ─┐
        uint40 deadline; // │
        bool isUnwound; // ─┘
        bool isUnwindThresholdMet; // ─┐
        uint96 subsidyAmount; //       │
        address rushERC20; // ─────────┘
        address originator;
    }

    /// @dev The local variables used in `_unwindLiquidity`.
    struct UnwindLiquidityLocalVars {
        bool isUnwindThresholdMet;
        uint256 amount0;
        uint256 amount1;
        uint256 wethBalance;
        uint256 rushERC20Balance;
        uint256 initialWETHReserve;
        uint256 wethSurplus;
        uint256 wethSurplusTax;
        uint256 totalReserveFee;
        uint256 wethToResupply;
        uint256 rushERC20ToResupply;
        uint256 rushERC20ToReward;
    }
}

/// @notice Namespace for the structs used in {RushLauncher}.
library RL {
    /**
     * @dev The parameters for launching a new ERC20 token market.
     * @param originator The address that originated the request (i.e., the user).
     * @param kind The kind of the ERC20 token template.
     * @param name The name of the ERC20 token.
     * @param symbol The symbol of the ERC20 token.
     * @param maxSupply The minted maximum supply of the ERC20 token.
     * @param data Additional data for the token initialization.
     * @param liquidityAmount The amount of base asset liquidity to deploy.
     * @param liquidityDuration The duration of the liquidity deployment (in seconds).
     * @param maxTotalFee The maximum total fee that can be collected for the liquidity deployment..
     */
    struct LaunchParams {
        address originator;
        bytes32 kind;
        string name;
        string symbol;
        uint256 maxSupply;
        bytes data;
        uint256 liquidityAmount;
        uint256 liquidityDuration;
        uint256 maxTotalFee;
    }
}

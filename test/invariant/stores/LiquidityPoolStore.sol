// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

/// @dev Storage variables needed by the LiquidityPool handler.
contract LiquidityPoolStore {
    // #region ----------------------------------=|+ VARIABLES +|=----------------------------------- //

    uint256 public totalAssets;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    function increaseTotalAssets(uint256 amount) external {
        totalAssets += amount;
    }

    function decreaseTotalAssets(uint256 amount) external {
        totalAssets -= amount;
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

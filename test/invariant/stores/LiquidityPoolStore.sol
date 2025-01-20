// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

/// @dev Storage variables needed by the LiquidityPool handler.
contract LiquidityPoolStore {
    // #region ----------------------------------=|+ VARIABLES +|=----------------------------------- //

    uint256 public balance;
    uint256 public outstandingAssets;
    uint256 public totalAssets;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    function increaseBalance(uint256 amount) external {
        balance += amount;
    }

    function decreaseBalance(uint256 amount) external {
        balance -= amount;
    }

    function increaseOutstandingAssets(uint256 amount) external {
        outstandingAssets += amount;
    }

    function decreaseOutstandingAssets(uint256 amount) external {
        outstandingAssets -= amount;
    }

    function increaseTotalAssets(uint256 amount) external {
        totalAssets += amount;
    }

    function decreaseTotalAssets(uint256 amount) external {
        totalAssets -= amount;
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

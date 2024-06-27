// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { LiquidityPool } from "src/LiquidityPool.sol";
import { BaseHandler } from "./BaseHandler.sol";
import { LiquidityPoolStore } from "../stores/LiquidityPoolStore.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Base contract with common logic needed by all handler contracts.
contract LiquidityPoolHandler is BaseHandler {
    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    LiquidityPool internal liquidityPool;
    LiquidityPoolStore internal liquidityPoolStore;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ VARIABLES +|=----------------------------------- //

    address internal immutable asset;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    constructor(LiquidityPool liquidityPool_, LiquidityPoolStore liquidityPoolStore_) {
        liquidityPool = liquidityPool_;
        liquidityPoolStore = liquidityPoolStore_;
        asset = liquidityPool.asset();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ HANDLER FUNCTIONS +|=------------------------------- //

    function deposit(uint256 amount, address receiver) public useNewSender(receiver) returns (uint256) {
        // Skip when the `receiver` address is the zero address.
        if (receiver == address(0)) {
            return 0;
        }
        // Skip when the `receiver` address is the LiquidityPool.
        if (receiver == address(liquidityPool)) {
            return 0;
        }
        // Bound the `amount` to the range (0, MAX_LIQUIDITY_AMOUNT).
        amount = bound(amount, 0, MAX_LIQUIDITY_AMOUNT);

        // Give required assets to the receiver.
        deal({ token: asset, to: receiver, give: amount });
        // Approve the LiquidityPool to spend the assets from the receiver.
        approveFrom({ token: asset, owner: receiver, spender: address(liquidityPool), amount: amount });
        // Increase the total assets managed by the LiquidityPool.
        liquidityPoolStore.increaseTotalAssets(amount);
        // Increase the balance of the LiquidityPool.
        liquidityPoolStore.increaseBalance(amount);
        // Deposit the assets into the LiquidityPool.
        return liquidityPool.deposit(amount, receiver);
    }

    function withdraw(uint256 amount, address receiver, address owner) public useNewSender(owner) returns (uint256) {
        // Skip when the `receiver` or `owner` address is the zero address.
        if (receiver == address(0) || owner == address(0)) {
            return 0;
        }
        // Skip when the `receiver` or `owner` address is the LiquidityPool.
        if (receiver == address(liquidityPool) || owner == address(liquidityPool)) {
            return 0;
        }
        // Bound the `amount` to the range (0, _assetReserve()).
        amount = bound(amount, 0, _assetReserve());

        // Give required LiquidityPool shares to the owner.
        uint256 shares = liquidityPool.previewWithdraw(amount);
        deal({ token: address(liquidityPool), to: owner, give: shares });
        // Decrease the total assets managed by the LiquidityPool.
        liquidityPoolStore.decreaseTotalAssets(amount);
        // Decrease the balance of the LiquidityPool.
        liquidityPoolStore.decreaseBalance(amount);
        // Withdraw the assets from the LiquidityPool.
        return liquidityPool.withdraw(amount, receiver, owner);
    }

    function dispatchAsset(address to, uint256 amount, bytes calldata data) public useNewSender(address(this)) {
        // Skip when the `to` address is the zero address.
        if (to == address(0)) {
            return;
        }
        // Skip when the `to` address is the LiquidityPool.
        if (to == address(liquidityPool)) {
            return;
        }
        // Skip given the asset reserve is zero.
        if (_assetReserve() == 0) {
            return;
        }
        // Bound the amount to the range (1, _assetReserve()).
        amount = bound(amount, 1, _assetReserve());

        // Decrease the balance of the LiquidityPool.
        liquidityPoolStore.decreaseBalance(amount);
        // Increase the outstanding assets of the LiquidityPool.
        liquidityPoolStore.increaseOutstandingAssets(amount);
        // Dispatch the assets to the `to` address.
        liquidityPool.dispatchAsset(to, amount, data);
    }

    function returnAsset(address from, uint256 amount, bytes calldata data) public useNewSender(address(this)) {
        // Skip when the `from` address is the zero address.
        if (from == address(0)) {
            return;
        }
        // Skip when the `from` address is the LiquidityPool.
        if (from == address(liquidityPool)) {
            return;
        }
        // Skip given the outstanding assets are zero.
        uint256 outstandingAssets = liquidityPool.outstandingAssets();
        if (outstandingAssets == 0) {
            return;
        }
        // Bound the amount to the range (1, outstandingAssets).
        amount = bound(amount, 1, outstandingAssets);

        // Give required assets to the `from` address.
        deal({ token: asset, to: from, give: amount });
        // Approve the LiquidityPool to spend the assets from the `from` address.
        approveFrom({ token: asset, owner: from, spender: address(liquidityPool), amount: amount });
        // Increase the balance of the LiquidityPool.
        liquidityPoolStore.increaseBalance(amount);
        // Decrease the outstanding assets of the LiquidityPool.
        liquidityPoolStore.decreaseOutstandingAssets(amount);
        // Return the assets from the `from` address to the LiquidityPool.
        liquidityPool.returnAsset(from, amount, data);
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ CALLBACK FUNCTIONS +|=------------------------------ //

    function onDispatchAsset(address to, uint256 amount, bytes calldata data) public { }

    function onReturnAsset(address from, uint256 amount, bytes calldata data) public { }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -------------------------=|+ INTERNAL CONSTANT FUNCTIONS +|=-------------------------- //

    /// @dev Returns the amount of assets held by the LiquidityPool.
    function _assetReserve() internal view returns (uint256) {
        return IERC20(asset).balanceOf(address(liquidityPool));
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

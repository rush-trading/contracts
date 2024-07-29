// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

/**
 * @title IReturnAssetCallback
 * @notice Any contract that calls ILiquidityPool#returnAsset must implement this interface.
 */
interface IReturnAssetCallback {
    /**
     * @dev Executes callback logic before receiving returned assets.
     * @param from The address from which assets are to be received.
     * @param amount The amount of assets to receive.
     * @param data Additional data.
     */
    function onReturnAsset(address from, uint256 amount, bytes calldata data) external;
}

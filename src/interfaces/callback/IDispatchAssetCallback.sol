// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

/**
 * @title IDispatchAssetCallback
 * @notice Any contract that calls ILiquidityPool#dispatchAsset must implement this interface.
 */
interface IDispatchAssetCallback {
    /**
     * @notice Executes callback logic after transferring assets.
     * @param to The address to which assets were transferred.
     * @param amount The amount of assets transferred.
     * @param data Additional data.
     */
    function onDispatchAsset(address to, uint256 amount, bytes calldata data) external;
}

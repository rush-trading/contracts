// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { IDispatchAssetCallback } from "src/interfaces/callback/IDispatchAssetCallback.sol";

/**
 * @title DispatchAssetCaller
 */
contract DispatchAssetCaller is IDispatchAssetCallback {
    /// @inheritdoc IDispatchAssetCallback
    function onDispatchAsset(address, uint256, bytes calldata) external pure override { }
}

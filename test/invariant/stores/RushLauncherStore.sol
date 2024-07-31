// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

/// @dev Storage variables needed by the RushLauncher handler.
contract RushLauncherStore {
    // #region ----------------------------------=|+ VARIABLES +|=----------------------------------- //

    mapping(uint256 id => address uniV2Pair) public deployments;
    mapping(address uniV2Pair => bool) public deploymentExists;
    uint256 public nextDeploymentId;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    function pushDeployment(address uniV2Pair) external {
        deployments[nextDeploymentId] = uniV2Pair;
        deploymentExists[uniV2Pair] = true;
        nextDeploymentId++;
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

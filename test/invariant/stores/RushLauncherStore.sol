// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

/// @dev Storage variables needed by the RushLauncher handler.
contract RushLauncherStore {
    // #region ----------------------------------=|+ VARIABLES +|=----------------------------------- //

    mapping(uint256 id => address pair) public deployments;
    uint256 public nextDeploymentId;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    function pushDeployment(address pair) external {
        deployments[nextDeploymentId] = pair;
        nextDeploymentId++;
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

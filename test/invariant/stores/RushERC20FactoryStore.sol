// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

/// @dev Storage variables needed by the RushERC20Factory handler.
contract RushERC20FactoryStore {
    // #region ----------------------------------=|+ VARIABLES +|=----------------------------------- //

    mapping(uint256 id => address implementation) public templates;
    uint256 public nextTemplateId;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    function pushTemplate(address implementation) external {
        templates[nextTemplateId] = implementation;
        nextTemplateId++;
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

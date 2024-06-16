// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all integration tests, both concrete and fuzz tests.
abstract contract Integration_Test is Base_Test {
    // #region -------------------------------=|+ SET-UP FUNCTION +|=-------------------------------- //

    function setUp() public virtual override {
        Base_Test.setUp();

        // Deploy the contracts.
        deployCore();

        // Grant roles.
        grantRolesCore();

        // Approve the contracts.
        approveCore();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Adds a template to the factory.
    function addTemplateToFactory(address implementation) internal {
        (, address caller,) = vm.readCallers();
        changePrank({ msgSender: users.admin });
        rushERC20Factory.addTemplate({ implementation: implementation });
        changePrank({ msgSender: caller });
    }

    /// @dev Creates an ERC20 from the factory.
    function createERC20FromFactory(bytes32 kind) internal returns (address) {
        (, address caller,) = vm.readCallers();
        changePrank({ msgSender: users.tokenDeployer });
        address erc20 = rushERC20Factory.createERC20({ originator: users.sender, kind: kind });
        changePrank({ msgSender: caller });
        return erc20;
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { RushERC20Factory } from "src/RushERC20Factory.sol";
import { IRushERC20 } from "src/interfaces/IRushERC20.sol";

import { Invariant_Test } from "./Invariant.t.sol";
import { RushERC20FactoryHandler } from "./handlers/RushERC20FactoryHandler.sol";
import { RushERC20FactoryStore } from "./stores/RushERC20FactoryStore.sol";

/// @dev Invariant tests for {RushERC20Factory}.
contract RushERC20Factory_Invariant_Test is Invariant_Test {
    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    RushERC20FactoryHandler internal rushERC20FactoryHandler;
    RushERC20FactoryStore internal rushERC20FactoryStore;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ SET-UP FUNCTION +|=------------------------------- //

    function setUp() public virtual override {
        Invariant_Test.setUp();
        deploy();
        grantRoles();

        // Target the RushERC20Factory handler for invariant testing.
        targetContract(address(rushERC20FactoryHandler));

        // Prevent these contracts from being fuzzed as `msg.sender`.
        excludeSender(address(rushERC20Factory));
        excludeSender(address(rushERC20FactoryStore));
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Deploys the contract.
    function deploy() internal {
        rushERC20Factory = new RushERC20Factory({ admin_: users.admin });
        vm.label({ account: address(rushERC20Factory), newLabel: "RushERC20Factory" });
        rushERC20FactoryStore = new RushERC20FactoryStore();
        vm.label({ account: address(rushERC20FactoryStore), newLabel: "RushERC20FactoryStore" });
        rushERC20FactoryHandler = new RushERC20FactoryHandler({
            rushERC20Factory_: rushERC20Factory,
            rushERC20FactoryStore_: rushERC20FactoryStore
        });
        vm.label({ account: address(rushERC20FactoryHandler), newLabel: "RushERC20FactoryHandler" });
    }

    /// @dev Grants roles.
    function grantRoles() internal {
        (, address caller,) = vm.readCallers();
        resetPrank(users.admin);
        rushERC20Factory.grantRole({ role: DEFAULT_ADMIN_ROLE, account: address(rushERC20FactoryHandler) });
        resetPrank(caller);
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ----------------------------------=|+ INVARIANTS +|=---------------------------------- //

    function invariant_NoKindCollisionForDifferentDescriptions() external view {
        uint256 id = rushERC20FactoryStore.nextTemplateId();
        for (uint256 i = 0; i < id; i++) {
            string memory descriptionI = IRushERC20(rushERC20FactoryStore.templates(i)).description();
            bytes32 kindI = keccak256(abi.encodePacked(descriptionI));
            for (uint256 j = i; j < id; j++) {
                string memory descriptionJ = IRushERC20(rushERC20FactoryStore.templates(j)).description();
                bytes32 kindJ = keccak256(abi.encodePacked(descriptionJ));
                if (kindI == kindJ && i != j) {
                    assertEq(Strings.equal(descriptionI, descriptionJ), true);
                }
            }
        }
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

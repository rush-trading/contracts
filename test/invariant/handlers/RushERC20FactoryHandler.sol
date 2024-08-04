// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { BaseHandler } from "./BaseHandler.sol";
import { RushERC20FactoryStore } from "../stores/RushERC20FactoryStore.sol";
import { IRushERC20Factory } from "src/interfaces/IRushERC20Factory.sol";
import { GoodRushERC20Mock } from "test/mocks/GoodRushERC20Mock.sol";

/// @notice Exposes {RushERC20Factory} functions to Foundry for invariant testing purposes.
contract RushERC20FactoryHandler is BaseHandler {
    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    IRushERC20Factory internal rushERC20Factory;
    RushERC20FactoryStore internal rushERC20FactoryStore;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ---------------------------------=|+ CONSTRUCTOR +|=---------------------------------- //

    constructor(IRushERC20Factory rushERC20Factory_, RushERC20FactoryStore rushERC20FactoryStore_) {
        rushERC20Factory = rushERC20Factory_;
        rushERC20FactoryStore = rushERC20FactoryStore_;
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region ------------------------------=|+ HANDLER FUNCTIONS +|=------------------------------- //

    function addTemplate(address implementation, uint256 version, string calldata description) external {
        // `vm.etch` is disallowed for addresses 0 < n < 10 and any already-existing contract.
        if (uint160(implementation) < 10 || implementation.code.length != 0) {
            return;
        }
        vm.etch(implementation, type(GoodRushERC20Mock).runtimeCode);
        GoodRushERC20Mock mock = GoodRushERC20Mock(implementation);
        mock.setDescription(description);
        mock.setVersion(version);
        rushERC20Factory.addTemplate(implementation);
        rushERC20FactoryStore.pushTemplate(implementation);
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

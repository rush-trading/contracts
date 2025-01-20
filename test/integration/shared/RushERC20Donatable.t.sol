// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26 <0.9.0;

import { IRushERC20 } from "src/interfaces/IRushERC20.sol";
import { RushERC20Donatable } from "src/tokens/RushERC20Donatable.sol";
import { Integration_Test } from "test/integration/Integration.t.sol";
import { LiquidityDeployerMock } from "test/mocks/LiquidityDeployerMock.sol";

contract RushERC20Donatable_Integration_Shared_Test is Integration_Test {
    // #region --------------------------------=|+ TEST CONTRACTS +|=-------------------------------- //

    LiquidityDeployerMock internal liquidityDeployerMock;

    // #endregion ----------------------------------------------------------------------------------- //

    // #region --------------------------------=|+ SET-UP FUNCTION +|=------------------------------- //

    function setUp() public virtual override {
        Integration_Test.setUp();
        deploy();
    }

    // #endregion ----------------------------------------------------------------------------------- //

    // #region -----------------------------------=|+ HELPERS +|=------------------------------------ //

    /// @dev Deploys the contract.
    function deploy() internal {
        address implementation = address(new RushERC20Donatable());
        addTemplate({ implementation: implementation });
        rushERC20 = IRushERC20(createRushERC20({ implementation: implementation }));
        vm.label({ account: address(rushERC20), newLabel: "RushERC20Donatable" });
        liquidityDeployerMock = new LiquidityDeployerMock();
        vm.label({ account: address(liquidityDeployerMock), newLabel: "LiquidityDeployerMock" });
    }

    /// @dev Initializes the contract.
    function initialize(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        address recipient,
        address donationBeneficiary,
        address liquidityDeployer
    )
        internal
    {
        bytes memory data = abi.encode(donationBeneficiary, liquidityDeployer);
        rushERC20.initialize({ name: name, symbol: symbol, maxSupply: maxSupply, recipient: recipient, data: data });
    }

    // #endregion ----------------------------------------------------------------------------------- //
}

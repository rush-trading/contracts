pragma solidity >=0.8.26 < 0.9.0;

import { RushERC20Taxable_Integration_Shared_Test } from "test/integration/shared/RushERC20Taxable.t.sol";
import { RushERC20Taxable } from "src/tokens/RushERC20Taxable.sol";

contract Exempted_Integration_Concrete_Test is RushERC20Taxable_Integration_Shared_Test {
    event ExchangePoolAdded(address exchangePool);
    event ExchangePoolRemoved(address exchangePool);
    event TaxExemptionUpdated(address indexed wallet, bool isExempted);

    function setUp() public virtual override {
        RushERC20Taxable_Integration_Shared_Test.setUp();
        initialize();
    }

    function test_RevertWhenNotOwner_addExemption(address fakeOwner, address newExemption) external {
        vm.assume(fakeOwner != users.sender);
        resetPrank({ msgSender: fakeOwner });
        vm.expectRevert();
        RushERC20Taxable(address(rushERC20)).addExemption(newExemption);
    }

    function test_RevertWhenNotOwner_removeExemption(address fakeOwner) external {
        vm.assume(fakeOwner != users.sender);
        resetPrank({ msgSender: fakeOwner });
        vm.expectRevert();
        RushERC20Taxable(address(rushERC20)).removeExemption(users.sender);
    }

    function test_whenRemoving_TaxExemptionUpdatedEvent() external {
        resetPrank({ msgSender: users.sender });
        address[] memory exchangePools = RushERC20Taxable(address(rushERC20)).getExchangePoolAddresses();

        vm.expectEmit({ emitter: address(rushERC20) });
        emit TaxExemptionUpdated(users.sender, false);
        RushERC20Taxable(address(rushERC20)).removeExemption(users.sender);
    }

    function test_whenAdding_TaxExemptionUpdatedEvent(address newExemption) external {
        resetPrank({ msgSender: users.sender });
        vm.assume(newExemption != users.sender);
        vm.assume(newExemption != address(0));
        vm.expectEmit({ emitter: address(rushERC20) });
        emit TaxExemptionUpdated(newExemption, true);
        RushERC20Taxable(address(rushERC20)).addExemption(newExemption);
    }

    function initialize() internal {
        bytes memory initData = abi.encode(users.sender, address(liquidityDeployer), defaults.RUSH_ERC20_TAX_BPS());
        RushERC20Taxable(address(rushERC20)).initialize(
            "TaxTokenTest", "TTT", defaults.RUSH_ERC20_SUPPLY(), address(500), initData
        );
    }
}

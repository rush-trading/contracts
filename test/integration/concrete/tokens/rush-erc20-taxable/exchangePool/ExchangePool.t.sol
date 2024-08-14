pragma solidity >=0.8.26 < 0.9.0;

import { RushERC20Taxable } from "src/tokens/RushERC20Taxable.sol";
import { RushERC20Taxable_Integration_Shared_Test } from "test/integration/shared/RushERC20Taxable.t.sol";

contract ExchangePool_Integration_Concrete_Test is RushERC20Taxable_Integration_Shared_Test {
    event ExchangePoolAdded(address indexed exchangePool);
    event ExchangePoolRemoved(address indexed exchangePool);

    function setUp() public virtual override {
        RushERC20Taxable_Integration_Shared_Test.setUp();
        initialize();
    }

    function test_RevertWhenNotOwner_addExchangePool(address fakeOwner, address newExchange) external {
        vm.assume(fakeOwner != users.sender);
        address[] memory exchangePools = RushERC20Taxable(address(rushERC20)).getExchangePoolAddresses();
        for (uint256 i = 0; i < exchangePools.length; i++) {
            vm.assume(newExchange != exchangePools[i]);
        }
        resetPrank({ msgSender: fakeOwner });
        vm.expectRevert();
        RushERC20Taxable(address(rushERC20)).addExchangePool(newExchange);
    }

    function test_RevertWhenNotOwner_removeExchangePool(address fakeOwner) external {
        vm.assume(fakeOwner != users.sender);
        address[] memory exchangePools = RushERC20Taxable(address(rushERC20)).getExchangePoolAddresses();
        resetPrank({ msgSender: fakeOwner });
        vm.expectRevert();
        RushERC20Taxable(address(rushERC20)).removeExchangePool(exchangePools[0]);
    }

    function test_ExchangePoolAddedEvent(address newExchange) external {
        resetPrank({ msgSender: users.sender });
        address[] memory exchangePools = RushERC20Taxable(address(rushERC20)).getExchangePoolAddresses();
        vm.assume(newExchange != address(0));
        for (uint256 i = 0; i < exchangePools.length; i++) {
            vm.assume(newExchange != exchangePools[i]);
        }
        vm.expectEmit({ emitter: address(rushERC20) });
        emit ExchangePoolAdded(newExchange);
        RushERC20Taxable(address(rushERC20)).addExchangePool(newExchange);
    }

    function test_ExchangePoolRemovedEvent() external {
        resetPrank({ msgSender: users.sender });
        address[] memory exchangePools = RushERC20Taxable(address(rushERC20)).getExchangePoolAddresses();
        vm.expectEmit({ emitter: address(rushERC20) });
        emit ExchangePoolRemoved(exchangePools[0]);
        RushERC20Taxable(address(rushERC20)).removeExchangePool(exchangePools[0]);
    }

    function initialize() internal {
        bytes memory initData = abi.encode(users.sender, address(liquidityDeployer), defaults.RUSH_ERC20_TAX_BPS());
        RushERC20Taxable(address(rushERC20)).initialize(
            "TaxTokenTest", "TTT", defaults.RUSH_ERC20_SUPPLY(), address(500), initData
        );
    }
}

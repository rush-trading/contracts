// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26 <0.9.0;

import { RushSmartLock } from "src/RushSmartLock.sol";
import { StakingRewards } from "src/StakingRewards.sol";
import { Fork_Test } from "test/fork/Fork.t.sol";

contract Constructor_RushLauncher_Fork_Test is Fork_Test {
    function test_Constructor() external {
        // Make Sender the caller in this test.
        resetPrank({ msgSender: users.sender });

        // Construct the contract.
        address stakingRewardsImpl = address(new StakingRewards());
        RushSmartLock constructedRushSmartLock = new RushSmartLock({
            aclManager_: address(aclManager),
            liquidityPool_: address(liquidityPool),
            stakingRewardsImpl_: stakingRewardsImpl,
            uniswapV2Factory_: address(uniswapV2Factory)
        });

        // Assert that the values were set correctly.
        address actualAclManager = address(constructedRushSmartLock.ACL_MANAGER());
        address expectedAclManager = address(aclManager);
        assertEq(actualAclManager, expectedAclManager, "ACL_MANAGER");

        address actualWeth = constructedRushSmartLock.WETH();
        address expectedWeth = address(weth);
        assertEq(actualWeth, expectedWeth, "WETH");

        address actualStakingRewardsImpl = constructedRushSmartLock.stakingRewardsImpl();
        address expectedStakingRewardsImpl = stakingRewardsImpl;
        assertEq(actualStakingRewardsImpl, expectedStakingRewardsImpl, "stakingRewardsImpl");

        address actualUniswapV2Factory = constructedRushSmartLock.UNISWAP_V2_FACTORY();
        address expectedUniswapV2Factory = address(uniswapV2Factory);
        assertEq(actualUniswapV2Factory, expectedUniswapV2Factory, "UNISWAP_V2_FACTORY");
    }
}

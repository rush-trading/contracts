# Deployment

All contract deployment scripts are written in Solidity and can be found in the [`script`](/script) directory.
Instructions are also provided below for running the deployment scripts using the `forge` CLI tool provided by Foundry.
Before running the deployment scripts, you should first set up a `.env` file with the necessary environment variables.
You can use the provided [`.env.example`](./.env.example) file as a template.

The instructions are organized by recommended order of deployment. They showcase how to deploy the contracts to the
Sepolia testnet, but you can pick any other chain listed under the `[rpc_endpoints]` section in
[`foundry.toml`](./foundry.toml#L61).

## Single Step

All protocol contracts can be deployed in a single step by running the following script:

```shell
# Set the deployment variables
export NETWORK="sepolia"

# Run the script
forge script script/DeployMaster.s.sol \
    --broadcast \
    --rpc-url ${NETWORK} \
    --sig "run()" \
    --verify
```

Protocol contracts (i.e., `LiquidityDeployer`, `RushLauncher`, and `RushRouter`) can also be upgraded in a single step
by running the following script:

````shell
# Set the deployment variables
export NETWORK="sepolia"
export ACL_MANAGER="<ADDRESS>"
export LIQUIDITY_POOL="<ADDRESS>"
export RUSH_ERC20_FACTORY="<ADDRESS>"
export OLD_LIQUIDITY_DEPLOYER="<ADDRESS>"
export OLD_RUSH_LAUNCHER="<ADDRESS>"
export OLD_RUSH_ROUTER="<ADDRESS>"

# Run the script
forge script script/UpgradeMaster.s.sol \
    --broadcast \
    --rpc-url ${NETWORK} \
    --sig "run(address,address,address,address,address,address)" \
    --verify \
    ${ACL_MANAGER} \
    ${LIQUIDITY_POOL} \
    ${RUSH_ERC20_FACTORY} \
    ${OLD_LIQUIDITY_DEPLOYER} \
    ${OLD_RUSH_LAUNCHER} \
    ${OLD_RUSH_ROUTER}
```

## Step-by-Step

The following sections provide step-by-step instructions for deploying each contract individually. You should replace
placeholders with the actual arguments you want to pass as follows:

- `<ADDRESS>`: An Ethereum address (e.g., `0x1234567890abcdef1234567890abcdef12345678`).
- `<WAD>`: A number in 18 decimal format (e.g., `1000000000000000000` representing 1 RushERC20 token, 1 ETH, or 100%
  rate).
- `<SECONDS>`: Number of seconds (e.g., `3600` representing 1 hour).

### Deploy `ACLManager`

```shell
# Set the deployment variables
export NETWORK="sepolia"
export ADMIN="<ADDRESS>"

# Run the script
forge script script/DeployACLManager.s.sol \
    --broadcast \
    --rpc-url ${NETWORK} \
    --sig "run(address)" \
    --verify \
    ${ADMIN}
````

### Deploy `LiquidityPool`

```shell
# Set the deployment variables
export NETWORK="sepolia"
export ACL_MANAGER="<ADDRESS>"
export ASSET="<ADDRESS>"
export MAX_TOTAL_DEPOSITS="<WAD>"

# Run the script
forge script script/DeployLiquidityPool.s.sol \
    --broadcast \
    --rpc-url ${NETWORK} \
    --sig "run(address,address,uint256)" \
    --verify \
    ${ACL_MANAGER} \
    ${ASSET} \
    ${MAX_TOTAL_DEPOSITS}
```

### Deploy `RushERC20Factory`

```shell
# Set the deployment variables
export NETWORK="sepolia"
export ACL_MANAGER="<ADDRESS>"

# Run the script
forge script script/DeployRushERC20Factory.s.sol \
    --broadcast \
    --rpc-url ${NETWORK} \
    --sig "run(address)" \
    --verify \
    ${ACL_MANAGER}
```

### Deploy `FeeCalculator`

```shell
# Set the deployment variables
export NETWORK="sepolia"
export BASE_FEE_RATE="<WAD>"
export OPTIMAL_UTILIZATION_RATIO="<WAD>"
export RATE_SLOPE_1="<WAD>"
export RATE_SLOPE_2="<WAD>"

# Run the script
forge script script/DeployFeeCalculator.s.sol \
    --broadcast \
    --rpc-url ${NETWORK} \
    --sig "run(uint256,uint256,uint256,uint256)" \
    --verify \
    ${BASE_FEE_RATE} \
    ${OPTIMAL_UTILIZATION_RATIO} \
    ${RATE_SLOPE_1} \
    ${RATE_SLOPE_2}
```

### Deploy `LiquidityDeployer`

```shell
# Set the deployment variables
export NETWORK="sepolia"
export ACL_MANAGER="<ADDRESS>"
export EARLY_UNWIND_THRESHOLD="<WAD>"
export FEE_CALCULATOR="<ADDRESS>"
export LIQUIDITY_POOL="<ADDRESS>"
export MAX_DEPLOYMENT_AMOUNT="<WAD>"
export MAX_DURATION="<SECONDS>"
export MIN_DEPLOYMENT_AMOUNT="<WAD>"
export MIN_DURATION="<SECONDS>"
export RESERVE="<ADDRESS>"
export RESERVE_FACTOR="<WAD>"
export SURPLUS_FACTOR="<WAD>"

# Run the script
forge script script/DeployLiquidityDeployer.s.sol \
    --broadcast \
    --rpc-url ${NETWORK} \
    --sig "run(address,uint256,address,address,uint256,uint256,uint256,uint256,address,uint256,uint256)" \
    --verify \
    ${ACL_MANAGER} \
    ${EARLY_UNWIND_THRESHOLD} \
    ${FEE_CALCULATOR} \
    ${LIQUIDITY_POOL} \
    ${MAX_DEPLOYMENT_AMOUNT} \
    ${MAX_DURATION} \
    ${MIN_DEPLOYMENT_AMOUNT} \
    ${MIN_DURATION} \
    ${RESERVE} \
    ${RESERVE_FACTOR} \
    ${SURPLUS_FACTOR}
```

### Deploy `RushLauncher`

```shell
# Set the deployment variables
export NETWORK="sepolia"
export ACL_MANAGER="<ADDRESS>"
export LIQUIDITY_DEPLOYER="<ADDRESS>"
export MAX_SUPPLY_LIMIT="<WAD>"
export MIN_SUPPLY_LIMIT="<WAD>"
export RUSH_ERC20_FACTORY="<ADDRESS>"
export UNISWAP_V2_FACTORY="<ADDRESS>"

# Run the script
forge script script/DeployRushLauncher.s.sol \
    --broadcast \
    --rpc-url ${NETWORK} \
    --sig "run(address,address,uint256,uint256,address,address)" \
    --verify \
    ${ACL_MANAGER} \
    ${LIQUIDITY_DEPLOYER} \
    ${MAX_SUPPLY_LIMIT} \
    ${MIN_SUPPLY_LIMIT} \
    ${RUSH_ERC20_FACTORY} \
    ${UNISWAP_V2_FACTORY}
```

### Deploy `RushRouter`

```shell
# Set the deployment variables
export NETWORK="sepolia"
export RUSH_LAUNCHER="<ADDRESS>"

# Run the script
forge script script/DeployRushRouter.s.sol \
    --broadcast \
    --rpc-url ${NETWORK} \
    --sig "run(address)" \
    --verify \
    ${RUSH_LAUNCHER}
```

### Upgrade `RushRouter`

```shell
# Set the deployment variables
export NETWORK="sepolia"
export ACL_MANAGER="<ADDRESS>"
export RUSH_LAUNCHER="<ADDRESS>"
export OLD_RUSH_ROUTER="<ADDRESS>"

# Run the script
forge script script/UpgradeRushRouter.s.sol \
    --broadcast \
    --rpc-url ${NETWORK} \
    --sig "run(address,address,address)" \
    --verify \
    ${ACL_MANAGER} \
    ${RUSH_LAUNCHER} \
    ${OLD_RUSH_ROUTER}
```

### Upgrade `RushRouterAlpha`

```shell
# Set the deployment variables
export NETWORK="sepolia"
export ACL_MANAGER="<ADDRESS>"
export RUSH_LAUNCHER="<ADDRESS>"
export OLD_RUSH_ROUTER="<ADDRESS>"
export VERIFIER="<ADDRESS>"

# Run the script
forge script script/UpgradeRushRouterAlpha.s.sol \
    --broadcast \
    --rpc-url ${NETWORK} \
    --sig "run(address,address,address,address)" \
    --verify \
    ${ACL_MANAGER} \
    ${RUSH_LAUNCHER} \
    ${OLD_RUSH_ROUTER} \
    ${VERIFIER}
```

### Assign Roles

The `ACLManager` contract is used to manage roles and permissions. Once the contracts are deployed, the `ADMIN` role
recipient should assign the necessary roles to the contracts as follows:

#### ASSET_MANAGER_ROLE

It is assigned to the `LiquidityDeployer` contract to allow it to manage the `LiquidityPool` assets. The necessary role
is assigned by calling the `addAssetManager` function on the `ACLManager` contract.

```solidity
aclManager.addAssetManager({
    account: address(liquidityDeployer)
});
```

#### LAUNCHER_ROLE

It is assigned to the `RushLauncher` contract to allow it to launch new RushERC20 tokens and deploy liquidity. The
necessary role is assigned by calling the `addLauncher` function on the `ACLManager` contract.

```solidity
aclManager.addLauncher({
    account: address(rushLauncher)
});
```

### ROUTER_ROLE

It is assigned to the `RushRouter` contract to allow it to call the `launch` function on the `RushLauncher` contract.
The necessary role is assigned by calling the `addRouter` function on the `ACLManager` contract.

```solidity
aclManager.addRouter({
    account: address(rushRouter)
});
```

### Take a Snapshot After First Deposit

After the very first deposit is made to the `LiquidityPool`, the `ADMIN` role recipient should invoke the
`takeSnapshotTotalAssets` function on the `LiquidityPool` contract to take a snapshot of the total assets and enable
proper deployment fee calculation for the `FeeCalculator` contract. The function is only needed to be called once after
the first deposit, as subsequent LiquidityPool interactions will automatically update the snapshot.

```solidity
liquidityPool.takeSnapshotTotalAssets();
```

### Add Token Templates

To allow the `RushLauncher` contract to launch new RushERC20 tokens, the `ADMIN` role recipient should add the token
templates to the `RushERC20Factory` contract. The token templates are added by calling the `addTemplate` function on the
`RushERC20Factory` contract. But first, the token templates should be deployed to the network.

```shell
# Set the deployment variables
export NETWORK="sepolia"

# Run the scripts
forge script script/DeployTokenRushERC20Basic.s.sol \
    --broadcast \
    --rpc-url ${NETWORK} \
    --sig "run()" \
    --verify

forge script script/DeployTokenRushERC20Taxable.s.sol \
    --broadcast \
    --rpc-url ${NETWORK} \
    --sig "run()" \
    --verify

forge script script/DeployTokenRushERC20Donatable.s.sol \
    --broadcast \
    --rpc-url ${NETWORK} \
    --sig "run()" \
    --verify
```

```solidity
rushERC20Factory.addTemplate(address(rushERC20Basic));
rushERC20Factory.addTemplate(address(rushERC20Taxable));
```

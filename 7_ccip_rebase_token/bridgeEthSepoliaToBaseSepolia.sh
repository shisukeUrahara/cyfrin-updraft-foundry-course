#!/bin/bash

set -euo pipefail
set -a
source .env
set +a

# Check required environment variables
: "${BASE_SEPOLIA_RPC_URL:?Need to set BASE_SEPOLIA_RPC_URL in .env}"
: "${ETH_SEPOLIA_RPC_URL:?Need to set ETH_SEPOLIA_RPC_URL in .env}"

# Define constants 
AMOUNT=100000

DEFAULT_BASE_SEPOLIA_LOCAL_KEY="0x7726827caac94a7f9e1b160f7ea819f172f7b6f9d2a97f992c38edeab82d4110"
DEFAULT_BASE_SEPOLIA_ADDRESS="0x36615Cf349d7F6344891B1e7CA7C72883F5dc049"

BASE_SEPOLIA_REGISTRY_MODULE_OWNER_CUSTOM="0x8A55C61227f26a3e2f217842eCF20b52007bAaBe"
BASE_SEPOLIA_TOKEN_ADMIN_REGISTRY="0x736D0bBb318c1B27Ff686cd19804094E66250e17"
BASE_SEPOLIA_ROUTER="0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93"
BASE_SEPOLIA_RNM_PROXY_ADDRESS="0x99360767a4705f68CcCb9533195B761648d6d807"
BASE_SEPOLIA_SEPOLIA_CHAIN_SELECTOR="6898391096552792247"
BASE_SEPOLIA_LINK_ADDRESS="0xE4aB69C077896252FAFBD49EFD26B5D171A32410"

SEPOLIA_REGISTRY_MODULE_OWNER_CUSTOM="0x62e731218d0D47305aba2BE3751E7EE9E5520790"
SEPOLIA_TOKEN_ADMIN_REGISTRY="0x95F29FEE11c5C55d26cCcf1DB6772DE953B37B82"
SEPOLIA_ROUTER="0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59"
SEPOLIA_RNM_PROXY_ADDRESS="0xba3f6251de62dED61Ff98590cB2fDf6871FbB991"
SEPOLIA_CHAIN_SELECTOR="16015286601757825753"
SEPOLIA_LINK_ADDRESS="0x779877A7B0D9E8603169DdbD7836e478b4624789"

# Compile and deploy the Rebase Token contract
forge build --via-ir

echo "Compiling and deploying the Rebase Token contract on Base Sepolia..."
BASE_SEPOLIA_REBASE_TOKEN_ADDRESS=$(forge create src/RebaseToken.sol:RebaseToken --rpc-url ${BASE_SEPOLIA_RPC_URL} --account metamaskSender1 --legacy  | awk '/Deployed to:/ {print $3}')
echo "BASE SEPOLIA rebase token address: $BASE_SEPOLIA_REBASE_TOKEN_ADDRESS"

# Compile and deploy the pool contract
echo "Compiling and deploying the pool contract on Base Sepolia..."
BASE_SEPOLIA_POOL_ADDRESS=$(forge create src/RebaseTokenPool.sol:RebaseTokenPool --rpc-url ${BASE_SEPOLIA_RPC_URL} --account metamaskSender1 --legacy --constructor-args ${BASE_SEPOLIA_REBASE_TOKEN_ADDRESS} "" ${BASE_SEPOLIA_RNM_PROXY_ADDRESS} ${BASE_SEPOLIA_ROUTER} | awk '/Deployed to:/ {print $3}')
echo "Pool address: $BASE_SEPOLIA_POOL_ADDRESS"

# Set the permissions for the pool contract
if [[ -z "$BASE_SEPOLIA_REBASE_TOKEN_ADDRESS" || -z "$BASE_SEPOLIA_POOL_ADDRESS" ]]; then
  echo "Error: One or more contract addresses are empty. Exiting."
  exit 1
fi

echo "Setting the permissions for the pool contract on BASE SEPOLIA..."
cast send ${BASE_SEPOLIA_REBASE_TOKEN_ADDRESS} "grantMintAndBurnRole(address)" ${BASE_SEPOLIA_POOL_ADDRESS} --rpc-url ${BASE_SEPOLIA_RPC_URL} --account metamaskSender1
echo "Pool permissions set"

# Set the CCIP roles and permissions

echo "Setting the CCIP roles and permissions on BASE SEPOLIA..."
cast send ${BASE_SEPOLIA_REGISTRY_MODULE_OWNER_CUSTOM} "registerAdminViaOwner(address)" ${BASE_SEPOLIA_REBASE_TOKEN_ADDRESS} --rpc-url ${BASE_SEPOLIA_RPC_URL} --account metamaskSender1
cast send ${BASE_SEPOLIA_TOKEN_ADMIN_REGISTRY} "acceptAdminRole(address)" ${BASE_SEPOLIA_REBASE_TOKEN_ADDRESS} --rpc-url ${BASE_SEPOLIA_RPC_URL} --account metamaskSender1
cast send ${BASE_SEPOLIA_TOKEN_ADMIN_REGISTRY} "setPool(address,address)" ${BASE_SEPOLIA_REBASE_TOKEN_ADDRESS} ${BASE_SEPOLIA_POOL_ADDRESS} --rpc-url ${BASE_SEPOLIA_RPC_URL} --account metamaskSender1
echo "CCIP roles and permissions set"

# 2. On Sepolia!

echo "Running the script to deploy the contracts on Sepolia..."
output=$(forge script ./script/Deployer.s.sol:TokenAndPoolDeployer --rpc-url ${ETH_SEPOLIA_RPC_URL} --account metamaskSender1 --broadcast)
echo "Contracts deployed and permission set on Sepolia"

# Extract the addresses from the output
ETH_SEPOLIA_REBASE_TOKEN_ADDRESS=$(echo "$output" | grep 'token: contract RebaseToken' | awk '{print $4}')
ETH_SEPOLIA_POOL_ADDRESS=$(echo "$output" | grep 'pool: contract RebaseTokenPool' | awk '{print $4}')

echo "Sepolia rebase token address: $ETH_SEPOLIA_REBASE_TOKEN_ADDRESS"
echo "Sepolia pool address: $ETH_SEPOLIA_POOL_ADDRESS"

# Deploy the vault 
echo "Deploying the vault on Sepolia..."
VAULT_ADDRESS=$(forge script ./script/Deployer.s.sol:VaultDeployer --rpc-url ${ETH_SEPOLIA_RPC_URL} --account metamaskSender1 --broadcast --sig "run(address)" ${ETH_SEPOLIA_REBASE_TOKEN_ADDRESS} | grep 'vault: contract Vault' | awk '{print $NF}')
echo "Vault address: $VAULT_ADDRESS"

# Configure the pool on Sepolia
echo "Configuring the pool on Sepolia..."
forge script ./script/ConfigurePool.s.sol:ConfigurePoolScript --rpc-url ${ETH_SEPOLIA_RPC_URL} --account metamaskSender1 --broadcast --sig "run(address,uint64,address,address,bool,uint128,uint128,bool,uint128,uint128)" ${ETH_SEPOLIA_POOL_ADDRESS} ${BASE_SEPOLIA_CHAIN_SELECTOR} ${BASE_SEPOLIA_POOL_ADDRESS} ${BASE_SEPOLIA_REBASE_TOKEN_ADDRESS} false 0 0 false 0 0

# Deposit funds to the vault
echo "Depositing funds to the vault on Sepolia..."
cast send ${VAULT_ADDRESS} --value ${AMOUNT} --rpc-url ${ETH_SEPOLIA_RPC_URL} --account metamaskSender1 "deposit()"

# Wait a beat for some interest to accrue

# Configure the pool on BASE SEPOLIA
echo "Configuring the pool on BASE SEPOLIA..."
cast send ${BASE_SEPOLIA_POOL_ADDRESS}  --rpc-url ${BASE_SEPOLIA_RPC_URL} --account metamaskSender1 "applyChainUpdates(uint64[],(uint64,bytes,bytes,(bool,uint128,uint128),(bool,uint128,uint128))[])" "[${SEPOLIA_CHAIN_SELECTOR}]" "[(${SEPOLIA_CHAIN_SELECTOR},$(cast abi-encode \"f(address)\" ${ETH_SEPOLIA_POOL_ADDRESS}),$(cast abi-encode \"f(address)\" ${ETH_SEPOLIA_REBASE_TOKEN_ADDRESS}),(false,0,0),(false,0,0))]"

# Bridge the funds using the script to base sepolia 
echo "Bridging the funds using the script to Base Sepolia..."
ETH_SEPOLIA_BALANCE_BEFORE=$(cast balance $(cast wallet address --account metamaskSender1) --erc20 ${ETH_SEPOLIA_REBASE_TOKEN_ADDRESS} --rpc-url ${ETH_SEPOLIA_RPC_URL})
echo "Sepolia balance before bridging: $ETH_SEPOLIA_BALANCE_BEFORE"
forge script ./script/BridgeTokens.s.sol:BridgeTokensScript --rpc-url ${ETH_SEPOLIA_RPC_URL} --account metamaskSender1 --broadcast --sig "sendMessage(address,uint64,address,uint256,address,address)" $(cast wallet address --account metamaskSender1) ${BASE_SEPOLIA_CHAIN_SELECTOR} ${ETH_SEPOLIA_REBASE_TOKEN_ADDRESS} ${AMOUNT} ${SEPOLIA_LINK_ADDRESS} ${SEPOLIA_ROUTER}
echo "Funds bridged to Base Sepolia"
ETH_SEPOLIA_BALANCE_AFTER=$(cast balance $(cast wallet address --account metamaskSender1) --erc20 ${ETH_SEPOLIA_REBASE_TOKEN_ADDRESS} --rpc-url ${ETH_SEPOLIA_RPC_URL})
echo "Sepolia balance after bridging: $ETH_SEPOLIA_BALANCE_AFTER"



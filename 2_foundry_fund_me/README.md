# FundMe Smart Contract

A decentralized crowdfunding smart contract built with Solidity and Foundry.

## Overview

This project implements a funding contract where users can:
- Send ETH to the contract (minimum 5 USD worth)
- Contract owner can withdraw all funds
- Uses Chainlink Price Feeds to ensure minimum funding amounts in USD

The contract includes gas-optimized functions and comprehensive test coverage.

## Features

- **ETH Funding**: Users can fund the contract with ETH
- **USD Price Minimum**: Enforces a minimum funding amount of 5 USD
- **Chainlink Integration**: Uses Chainlink price feeds for ETH/USD conversion
- **Owner Withdrawal**: Only the contract owner can withdraw funds
- **Gas Optimization**: Includes a gas-optimized withdrawal function

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

## Setup

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. Install dependencies:
   ```bash
   forge install
   ```

3. Build the project:
   ```bash
   forge build
   ```

## Testing

Run the test suite:
```bash
forge test
```

For more detailed test output:
```bash
forge test -vv
```

To check test coverage:
```bash
forge coverage
```

## Deployment

### Local Deployment

Start a local Anvil chain:
```bash
anvil
```

Deploy to the local chain:
```bash
forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

### Testnet Deployment (Sepolia)

Create a `.env` file with your configuration (use `.env.example` as a template):
```bash
cp .env.example .env
```

Then edit the `.env` file with your values:
```
SEPOLIA_RPC_URL=<your-sepolia-rpc-url>
PRIVATE_KEY=<your-private-key>
ETHERSCAN_API_KEY=<your-etherscan-api-key>
```

Load the environment variables:
```bash
source .env
```

Deploy to Sepolia:
```bash
forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
```

Or use the Makefile command:
```bash
make deploy-sepolia
```

## Interacting with the Contract

### Fund the Contract

```bash
forge script script/Interactions.s.sol:FundFundMe --rpc-url http://localhost:8545 --private-key <your-private-key> --broadcast
```

Or use the Makefile command:
```bash
make fund
```

### Withdraw Funds (Owner Only)

```bash
forge script script/Interactions.s.sol:WithdrawFundMe --rpc-url http://localhost:8545 --private-key <your-private-key> --broadcast
```

Or use the Makefile command:
```bash
make withdraw
```

## Makefile Commands

This project includes a Makefile for convenience:

- `make build`: Build the project
- `make test`: Run tests
- `make deploy-sepolia`: Deploy to Sepolia testnet
- `make fund`: Fund the contract
- `make withdraw`: Withdraw funds from the contract
- `make format`: Format code
- `make anvil`: Start a local Anvil chain
- `make help`: Show available commands

## Project Structure

- `src/`: Smart contract source files
  - `FundMe.sol`: Main contract
  - `PriceConverter.sol`: Library for ETH/USD conversion
- `test/`: Test files
  - `unit/`: Unit tests
  - `integration/`: Integration tests
- `script/`: Deployment and interaction scripts
  - `DeployFundMe.s.sol`: Deployment script
  - `Interactions.s.sol`: Contract interaction scripts
  - `HelperConfig.s.sol`: Configuration helper
- `lib/`: Dependencies (Chainlink contracts, etc.)

## Environment Variables

- `SEPOLIA_RPC_URL`: RPC URL for Sepolia testnet
- `PRIVATE_KEY`: Your wallet's private key for deployment
- `ETHERSCAN_API_KEY`: API key for verifying contracts on Etherscan

## License

MIT

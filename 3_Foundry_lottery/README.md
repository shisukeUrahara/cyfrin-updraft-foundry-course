# Smart Contract Raffle

A provably fair, decentralized raffle system built on Ethereum using Chainlink VRF and Automation.

## Overview

This project implements a fully decentralized raffle system where:

- Users can enter by paying an entrance fee
- A random winner is selected at regular intervals
- Winner selection is verifiably random using Chainlink VRF
- Automatic winner selection is handled by Chainlink Automation
- The entire prize pool is transferred to the winner

## Key Features

- **Verifiable Randomness**: Uses Chainlink VRF (Verifiable Random Function) to ensure fair winner selection
- **Automated Execution**: Leverages Chainlink Automation for automatic prize distribution
- **Gas Efficient**: Optimized for minimal gas costs
- **Secure**: Thoroughly tested with comprehensive unit and staging tests
- **Multi-chain Support**: Configurable for different networks (Ethereum Mainnet, Sepolia, Anvil)

## Technical Details

- Built with Solidity 0.8.19+
- Uses Chainlink VRF V2.5 for randomness
- Implements Chainlink Automation for time-based triggers
- Developed with Foundry for testing and deployment

## Project Structure

- `src/Raffle.sol`: Main raffle contract
- `script/`: Deployment and interaction scripts
  - `DeployRaffle.s.sol`: Handles deployment
  - `HelperConfig.s.sol`: Network configuration
  - `Interactions.s.sol`: Scripts for interacting with the contract
- `test/`: Comprehensive test suite
  - `unit/`: Unit tests for all contract functions
  - `staging/`: Integration tests for deployed contracts

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Chainlink VRF Subscription](https://vrf.chain.link/) (for live deployments)

### Installation

Clone the repository
git clone <repository-url>
cd smart-contract-raffle
Install dependencies
forge install


### Build
forge build


### Test

shell
Run all tests
forge test
Run unit tests
forge test --match-path test/unit/
Run staging tests
forge test --match-path test/staging/
Get test coverage
forge coverage

### Deploy

Deploy to local Anvil chain
forge script script/DeployRaffle.s.sol --rpc-url anvil --broadcast
Deploy to Sepolia testnet
forge script script/DeployRaffle.s.sol --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast --verify
Deploy to Ethereum mainnet
forge script script/DeployRaffle.s.sol --rpc-url mainnet --private-key $PRIVATE_KEY --broadcast --verify


## Usage

1. Deploy the contract
2. Fund the VRF subscription with LINK tokens
3. Users can enter the raffle by calling `enterRaffle()` with the entrance fee
4. After the interval passes, Chainlink Automation will trigger `performUpkeep()`
5. Chainlink VRF will provide randomness and select a winner
6. The entire prize pool will be transferred to the winner automatically

## License

MIT

# Foundry NFT Project

This project demonstrates the implementation of two different NFT contracts using Foundry, a blazing fast Ethereum development toolkit. The project includes both a basic NFT implementation and a dynamic mood NFT that can change its appearance based on the owner's preference.

## Project Structure

```
├── src/
│   ├── BasicNft.sol      # Basic NFT implementation
│   └── MoodNft.sol       # Dynamic mood NFT implementation
├── script/
│   ├── DeployBasicNft.s.sol  # Deployment script for BasicNft
│   ├── DeployMoodNft.s.sol   # Deployment script for MoodNft
│   └── Interactions.s.sol    # Script for interacting with deployed contracts
├── test/
│   ├── BasicNftTest.t.sol    # Tests for BasicNft
│   ├── MoodNftTest.t.sol     # Tests for MoodNft
│   ├── DeployBasicNftTest.t.sol  # Tests for BasicNft deployment
│   ├── DeployMoodNftTest.t.sol   # Tests for MoodNft deployment
│   └── InteractionsTest.t.sol    # Tests for contract interactions
├── img/
│   ├── happy.svg         # Happy mood SVG image
│   ├── sad.svg          # Sad mood SVG image
│   ├── pug.png          # Pug NFT image
│   ├── shiba-inu.png    # Shiba Inu NFT image
│   └── st-bernard.png   # St. Bernard NFT image
└── foundry.toml         # Foundry configuration file
```

## Contract Overview

### BasicNft

A simple ERC721 implementation that allows users to mint NFTs with predefined images. Each NFT has a unique token ID and can be owned by different addresses.

### MoodNft

A dynamic NFT that can change its appearance between happy and sad states. The NFT's appearance is stored on-chain as SVG data, and owners can flip between moods using the `flipMood` function.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Solidity ^0.8.20
- Git

## Setup

1. Clone the repository:

```bash
git clone <repository-url>
cd <repository-name>
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

### Run All Tests

```bash
forge test
```

### Run Tests with Verbose Output

```bash
forge test -vv
```

### Run Tests with Coverage Report

```bash
forge coverage
```

### Run Specific Test Files

```bash
forge test --match-path test/BasicNftTest.t.sol
forge test --match-path test/MoodNftTest.t.sol
```

## Deployment

### Deploy BasicNft

```bash
forge script script/DeployBasicNft.s.sol:DeployBasicNft --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast
```

### Deploy MoodNft

```bash
forge script script/DeployMoodNft.s.sol:DeployMoodNft --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast
```

## Contract Interactions

### Mint BasicNft

```bash
forge script script/Interactions.s.sol:MintBasicNft --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast
```

## Test Coverage

The project maintains high test coverage across all contracts:

- `BasicNft.sol`: 91.67% line coverage
- `MoodNft.sol`: 96.77% line coverage
- `DeployBasicNft.s.sol`: 100% line coverage
- `DeployMoodNft.s.sol`: 100% line coverage
- `Interactions.s.sol`: 57.14% line coverage

## Key Features

### BasicNft

- Mint NFTs with predefined images
- Unique token IDs
- ERC721 standard compliance
- Owner tracking
- Token URI management

### MoodNft

- Dynamic SVG-based NFTs
- Mood flipping functionality
- On-chain image storage
- Owner and approved operator controls
- Base64 encoded metadata

## Development

### Code Formatting

```bash
forge fmt
```

### Gas Snapshots

```bash
forge snapshot
```

### Local Node

```bash
anvil
```

## Testing Environment

The project uses Foundry's testing framework with the following features:

- VM pranking for address spoofing
- Event recording and verification
- State snapshotting
- Gas reporting
- Coverage analysis

## Security Considerations

- Owner-only functions
- Approved operator controls
- Safe minting implementation
- Input validation
- Error handling

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

# OurToken ERC20 Implementation

This project demonstrates a simple ERC20 token implementation using OpenZeppelin contracts and Foundry for testing.

## Overview

- `OurToken.sol`: A simple ERC20 token implementation that inherits from OpenZeppelin's ERC20 contract.
- Tests for the token functionality in the `test` directory.
- Deployment script in the `script` directory.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

## Installation

1. Clone the repository
2. Install dependencies:
```bash
forge install
```

## Testing

Run the tests with:

```bash
forge test
```

For more verbose output:

```bash
forge test -vv
```

## Deployment

To deploy the token to a local network:

```bash
forge script script/DeployOurToken.s.sol --rpc-url http://localhost:8545 --broadcast
```

## License

MIT

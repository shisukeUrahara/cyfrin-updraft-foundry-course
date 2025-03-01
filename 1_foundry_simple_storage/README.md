# SimpleStorage Foundry Project

**A simple Ethereum smart contract for storing and retrieving values using Foundry.**

## About Foundry

Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## SimpleStorage Contract

This project contains a `SimpleStorage` contract that allows:
- Storing a favorite number
- Retrieving the stored number
- Adding people with their favorite numbers
- Looking up a person's favorite number by name

## Usage

### Build

```shell
$ forge build
```

### Format

```shell
$ forge fmt
```

### Compile

```shell
$ forge compile
```

### Test

```shell
$ forge test
```

### Running local anvil chain

```shell
$ anvil
```

### Wallet Management
Import a private key to use for deployments:

```shell
$ cast wallet import metamaskSender1 --interactive #you can use any name as per your choice for metamaskSender1
```

List imported wallets for deployment:
```shell
$ cast wallet list
```

Deploy the contract:
```shell
$ forge script script/DeploySimpleStorage.s.sol --rpc-url <your_rpc_url> --account metamaskSender1 --sender <your_public_wallet_address_for_metamaskSender1> --broadcast
```

### Help
```shell
$ forge --help
$ anvil --help
$ cast --help
```

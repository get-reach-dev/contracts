## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

Token

```shell
forge create ./src/Token.sol:Token --rpc-url https://sepolia.base.org --account deployer --constructor-args Reach Reach
```

Distribution

```shell
forge create ./src/Distribution.sol:ReachDistribution --rpc-url https://sepolia.base.org --account deployer --constructor-args {tokenAddress} {signerAddress}
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

//TOKEN
Deployed to: 0x0836feE34Bd4403213e6ccA241576DDa315D8eEa

//Distribution
Deployed to: 0xE51707da336Fe26821EfaD0caA8B8d8D6AFF10FB

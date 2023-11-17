## Project Overview

This project is a second version of NFT Protect protocol. The main contracts involved are:

- UserRegistry: Manages users and their successors.
- RequestsHub: Handles requests for ownership adjustment, ownership restoration, and burning of entities.
- NFTProtect2: Applies ownership adjustments, ownership restoration, and burning of entities.

The project also includes hardhat scripts for deploying these contracts (deploy.ts), verifying them (verify.ts), and updating the README.md file with the deployed contract addresses (updateReadme.ts).


## Deployment

Contracts are deployed using the deploy.ts script. This script checks if a contract has already been deployed on the network, and if not, deploys it.
```shell
npx hardhat compile
npx hardhat run scripts/deploy.ts --network sepolia
```
or with your package manager:
```shell
yarn build
yarn deploy --network sepolia
```

## Verification

After deployment, contracts can be verified using the verify.ts script. This script reads the contract data from contracts.json and verifies each contract on the network.
```shell
npx hardhat run scripts/verify.ts --network sepolia
```
or with your package manager:
```shell
yarn verify --network sepolia
```

## Configuration

To configure contracts automatically after deployment, run the following:
```shell
npx hardhat run scripts/configure.ts --network sepolia
```
or with your package manager:
```shell
yarn configure --network sepolia
```
This script performs smart contracts configuration based on contracts.json and arbitrators.json.

## Contracts
### Sepolia
- [ArbitratorRegistry](https://sepolia.etherscan.io/address/0x8557b772ca78e03cc7403d9e4839aa832716f384)
- [UserDIDDummyAllowAll](https://sepolia.etherscan.io/address/0xec42cfc1017c6d3349509559721f23e08e8bd4d3)
- [NFTProtect2](https://sepolia.etherscan.io/address/0x8ef041e6907fd2b8e43272fe5a558a993384f03e)
- [UserRegistry](https://sepolia.etherscan.io/address/0x0ad1d72235a939f5bd090f5f2bd42b81851aa8de)
- [RequestsHub](https://sepolia.etherscan.io/address/0x13367954799c3c89452b0a634f898f5d2f3d6e84)
- [ProtectorFactory721](https://sepolia.etherscan.io/address/0xbfdc9f6ba697312a8a86a19aaff036e720fce016)
- [Coupons](https://sepolia.etherscan.io/address/0x47B75a11a5Aa922C01f3808e25eBea9D55Eec57F)

##
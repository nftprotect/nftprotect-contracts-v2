## Project Overview

This project is a second version of NFT Protect protocol. The main contracts involved are:

- UserRegistry: Manages users and their successors.
- RequestsHub: Handles requests for ownership adjustment, ownership restoration, and burning of entities.
- NFTProtect2: Applies ownership adjustments, ownership restoration, and burning of entities.

The project also includes hardhat scripts for deploying these contracts (deploy.ts), verifying them (verify.ts), and updating the README.md file with the deployed contract addresses (updateReadme.ts).


## Deployment

Contracts are deployed using the deploy.ts script. This script checks if a contract has already been deployed on the network, and if not, deploys it.
```shell
yarn build
yarn deploy --network sepolia
```

## Verification

After deployment, contracts can be verified using the verify.ts script. This script reads the contract data from contracts.json and verifies each contract on the network.
```shell
yarn verify --network sepolia
```

## Configuration

To configure contracts automatically after deployment, run the following:
```shell
yarn configure --network sepolia
```
This script performs smart contracts configuration based on contracts.json and arbitrators.json.

## Contracts
### Sepolia
- [ArbitratorRegistry](https://sepolia.etherscan.io/address/0xfba4f779f283818717c8be49864b98785b74d680)
- [UserDIDDummyAllowAll](https://sepolia.etherscan.io/address/0xc29da1a7998414374c05664fedc90ecbefbe5b2d)
- [NFTProtect2](https://sepolia.etherscan.io/address/0x99b3b14ce59cc5e1430558f1c3bee3c43ee7fbaa)
- [UserRegistry](https://sepolia.etherscan.io/address/0x04e41851820f02066341488e03e38187f3c52702)
- [Coupons](https://sepolia.etherscan.io/address/0x7A65807049e545AA72234BEC6563fE593605b65b)
- [RequestsHub](https://sepolia.etherscan.io/address/0x69b34502cc9e31c09b18435f0e01a0f516d3ff3f)
- [ProtectorFactory721](https://sepolia.etherscan.io/address/0xe83c71eb19a45a932e405f57841f08fd26a454b9)

##
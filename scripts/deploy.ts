import { readFileSync, writeFileSync, existsSync } from 'fs';
import { GetContractReturnType } from "viem";
import hre from "hardhat";

const jsonFilePath = './contracts.json'; // Path to your JSON file

let contractsData = existsSync(jsonFilePath) ? JSON.parse(readFileSync(jsonFilePath, 'utf-8')) : {};

async function getOrDeployContract(contractName: string, deployFunction: () => Promise<GetContractReturnType>) {
  const networkName = hre.network.name;
  let networkData = contractsData[networkName] || {};

  if (networkData[contractName]) {
    const contract = await hre.viem.getContractAt(contractName, networkData[contractName]);
    console.log(`Existing ${contractName}: ${contract.address}`)
    return contract;
  } else {
    const contract = await deployFunction();
    console.log(`Deployed ${contractName}: ${contract.address}`)
    networkData[contractName] = contract.address;
    contractsData[networkName] = networkData;
    return contract;
  }
}

async function deployNFTProtect2() {
    const nftProtect2 = await hre.viem.deployContract("NFTProtect2");
    return nftProtect2;
}

async function deployUserRegistry(arbitratorRegistry: GetContractReturnType, did: GetContractReturnType, nftProtect2: GetContractReturnType) {
    const userRegistry = await hre.viem.deployContract("UserRegistry", [arbitratorRegistry.address, did.address, nftProtect2.address]);
    return userRegistry;
}

async function getCouponsAddress(userRegistry: GetContractReturnType) {
    // Get the address of the Coupons contract
    const couponsAddress = await userRegistry.read._coupons();
    console.log("Coupons contract address:", couponsAddress)
    // Save the Coupons contract address to the contractsData
    let networkData = contractsData[hre.network.name] || {};
    networkData["Coupons"] = couponsAddress;
    contractsData[hre.network.name] = networkData;
    return couponsAddress
}

async function deployRequestsHub(arbitratorRegistry: GetContractReturnType, nftProtect2: GetContractReturnType) {
    const requestsHub = await hre.viem.deployContract("RequestsHub", [arbitratorRegistry.address, nftProtect2.address]);
    return requestsHub;
}

async function deployProtectorFactory721(nftProtect2: GetContractReturnType) {
    const protectorFactory721 = await hre.viem.deployContract("ProtectorFactory721", [nftProtect2.address]);
    return protectorFactory721;
}

async function deployArbitratorRegistry() {
    const arbRegistry = await hre.viem.deployContract("ArbitratorRegistry");
    return arbRegistry;
}

async function deployDID() {
    const did = await hre.viem.deployContract("UserDIDDummyAllowAll");
    return did;
}


async function main() {
    try {
        const arbitratorRegistry = await getOrDeployContract("ArbitratorRegistry", deployArbitratorRegistry);
        const did = await getOrDeployContract("UserDIDDummyAllowAll", deployDID);
        const nftProtect2 = await getOrDeployContract("NFTProtect2", deployNFTProtect2);
        const userRegistry = await getOrDeployContract("UserRegistry", () => deployUserRegistry(arbitratorRegistry, did, nftProtect2));
        await getCouponsAddress(userRegistry)
        const requestsHub = await getOrDeployContract("RequestsHub", () => deployRequestsHub(arbitratorRegistry, nftProtect2));
        const protectorFactory721 = await getOrDeployContract("ProtectorFactory721", () => deployProtectorFactory721(nftProtect2));
    } catch (error) {
        console.error(error);
        process.exitCode = 1;
    } finally {
        // Write the updated data back to the file after all operations
        writeFileSync(jsonFilePath, JSON.stringify(contractsData, null, 2));
    }
}

main();
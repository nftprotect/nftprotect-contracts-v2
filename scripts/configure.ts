import { readFileSync, existsSync } from 'fs';
import hre from "hardhat";

const contractsFilePath = './contracts.json'; // Path to your JSON file
const arbitratorsFilePath = './arbitrators.json'; // Path to your arbitrators file
const nullAddress = '0x0000000000000000000000000000000000000000'
const networkName = hre.network.name;

let contractsData = existsSync(contractsFilePath) ? JSON.parse(readFileSync(contractsFilePath, 'utf-8')) : {};
let arbitratorsData = existsSync(arbitratorsFilePath) ? JSON.parse(readFileSync(arbitratorsFilePath, 'utf-8')) : {};
let networkData = contractsData[networkName] || {};

async function configureArbitratorRegistry() {
    let arbitratorData = arbitratorsData[networkName];

    if (!networkData["ArbitratorRegistry"]) {
        throw Error("ArbitratorRegistry contract address not found in contracts.json")
    }

    if (!arbitratorData) {
        throw Error("Arbitrator data not found in arbitrators.json")
    }

    const contract = await hre.viem.getContractAt("ArbitratorRegistry", networkData["ArbitratorRegistry"]);

    const isConfigured = await contract.read.checkArbitrator([1]);
    if (isConfigured) {
        console.log(`Arbitrator already set`);
        return contract;
    } else {
        console.log(`Setting Arbitrator...`);
    }

    await contract.write.addArbitrator([arbitratorData.name, arbitratorData.address, arbitratorData.extraData]);
    return contract
}

async function setNFTProtectRequestHub() {  
    if (!networkData["NFTProtect2"] || !networkData["RequestsHub"]) {
        throw Error("NFTProtect2 or RequestsHub contract address not found in contracts.json");
    }
  
    const contract = await hre.viem.getContractAt("NFTProtect2", networkData["NFTProtect2"]);
    const requestHubAddress = await contract.read._requestHub();
    if (requestHubAddress !== nullAddress) {
        console.log(`RequestsHub ${requestHubAddress} already set`);
        return contract;
    }
    console.log(`Setting RequestsHub ${networkData["RequestsHub"]}...`);
    await contract.write.setRequestHub([networkData["RequestsHub"]]);
    return contract;
}
  
async function setNFTProtectUserRegistry() {  
    if (!networkData["NFTProtect2"] || !networkData["UserRegistry"]) {
      throw Error("NFTProtect2 or UserRegistry contract address not found in contracts.json");
    }
  
    const contract = await hre.viem.getContractAt("NFTProtect2", networkData["NFTProtect2"]);
    const userRegistryAddress = await contract.read._userRegistry();
  
    if (userRegistryAddress !== nullAddress) {
      console.log(`NFTProtect2: UserRegistry ${userRegistryAddress} already set`);
      return contract;
    }
    
    console.log(`Setting UserRegistry ${networkData["UserRegistry"]}...`);
    await contract.write.setUserRegistry([networkData["UserRegistry"]]);
    return contract
}

async function registerProtectorFactory() {
    if (!networkData["NFTProtect2"] || !networkData["ProtectorFactory721"]) {
        throw Error("NFTProtect2 or ProtectorFactory721 contract address not found in contracts.json");
    }

    const contract = await hre.viem.getContractAt("NFTProtect2", networkData["NFTProtect2"]);
    const factoryStatus = await contract.read._factories([networkData["ProtectorFactory721"]]);
    if (factoryStatus === 0n) {
        console.log(`Registering ProtectorFactory721 ${networkData["ProtectorFactory721"]}...`);
        await contract.write.registerProtectorFactory([networkData["ProtectorFactory721"]]);
    } else {
        console.log(`ProtectorFactory721 ${networkData["ProtectorFactory721"]} is already registered`);
    }

    return contract;
}

async function main() {
    try {
        console.log(`1. ArbitratorRegistry:`);
        const arbRegistry = await configureArbitratorRegistry();
        console.log(`ArbitratorRegistry ${arbRegistry.address} configured successfully`);
        console.log(`2. NFTProtect2:`);
        await setNFTProtectRequestHub();
        await setNFTProtectUserRegistry();
        const nftProtect = await registerProtectorFactory();
        console.log(`NFTProtect2 ${nftProtect.address} configured successfully`);

    } catch (error) {
        console.error(error);
        process.exitCode = 1;
    }
}

main();
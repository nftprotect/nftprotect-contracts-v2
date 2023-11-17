import { readFileSync, existsSync } from 'fs';
import hre from "hardhat";
import { PublicClient } from "viem";
import { 
    technicalOwner,
    metaEvidenceLoader,
    basicFeeWei, 
    ultraFeeWei 
} from '../contracts.config';

const contractsFilePath = './contracts.json'; // Path to your JSON file
const arbitratorsFilePath = './arbitrators.json'; // Path to your arbitrators file
const nullAddress = '0x0000000000000000000000000000000000000000'
const networkName = hre.network.name;

let contractsData = existsSync(contractsFilePath) ? JSON.parse(readFileSync(contractsFilePath, 'utf-8')) : {};
let arbitratorsData = existsSync(arbitratorsFilePath) ? JSON.parse(readFileSync(arbitratorsFilePath, 'utf-8')) : {};
let networkData = contractsData[networkName] || {};
let client: PublicClient;

async function processTransaction(hash :`0x${string}`) {
    if (client) {
        console.log(`Waiting for transaction receipt ( ${hash} )...`)
        const receipt = await client.waitForTransactionReceipt({hash})
        if (receipt.status === 'success') {
            console.log('Transaction successfull')
        } else {
            console.log('Transaction unsuccessfull:', receipt)
            throw Error(`Transaction error: ${hash}`)
        }
    }
}

// ArbitratorRegistry

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

    const hash = await contract.write.addArbitrator([arbitratorData.name, arbitratorData.address, arbitratorData.extraData]);
    await processTransaction(hash)
    return contract
}

// NFTProtect 2

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
    const hash = await contract.write.setRequestHub([networkData["RequestsHub"]]);
    await processTransaction(hash)
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
    const hash = await contract.write.setUserRegistry([networkData["UserRegistry"]]);
    await processTransaction(hash)
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
        const hash = await contract.write.registerProtectorFactory([networkData["ProtectorFactory721"]]);
        await processTransaction(hash)
    } else {
        console.log(`ProtectorFactory721 ${networkData["ProtectorFactory721"]} is already registered`);
    }
    return contract;
}

async function setTechnicalOwner() {
    if (!networkData["NFTProtect2"]) {
        throw Error("NFTProtect2 contract address not found in contracts.json");
    }

    const contract = await hre.viem.getContractAt("NFTProtect2", networkData["NFTProtect2"]);
    const currentTechnicalOwner = await contract.read._technicalOwner();

    if (currentTechnicalOwner.toLowerCase() !== technicalOwner.toLowerCase()) {
        console.log(`Setting technicalOwner to ${technicalOwner}...`);
        const hash = await contract.write.setTechnicalOwner([technicalOwner]);
        await processTransaction(hash)
    } else {
        console.log(`TechnicalOwner is already set to ${technicalOwner}`);
    }
    return contract;
}

// UserRegistry

async function configureUserRegistryFees() {
    if (!networkData["UserRegistry"]) {
        throw Error("UserRegistry contract address not found in contracts.json");
    }

    const contract = await hre.viem.getContractAt("UserRegistry", networkData["UserRegistry"]);

    const currentBasicFee = await contract.read._feeWei([0]);
    const currentUltraFee = await contract.read._feeWei([1]);

    if (currentBasicFee !== basicFeeWei) {
        console.log(`Setting basicFeeWei to ${basicFeeWei}...`);
        const hash = await contract.write.setFee([0, basicFeeWei]);
        await processTransaction(hash)
    } else {
        console.log(`BasicFeeWei is already set to ${basicFeeWei}`);
    }

    if (currentUltraFee !== ultraFeeWei) {
        console.log(`Setting ultraFeeWei to ${ultraFeeWei}...`);
        const hash = await contract.write.setFee([1, ultraFeeWei]);
        await processTransaction(hash)
    } else {
        console.log(`UltraFeeWei is already set to ${ultraFeeWei}`);
    }

    return contract;
}

async function main() {
    try {
        client = await hre.viem.getPublicClient();
        if (client) {
            console.log(`1. ArbitratorRegistry:`);
            const arbRegistry = await configureArbitratorRegistry();
            console.log(`ArbitratorRegistry ${arbRegistry.address} configured successfully`);
            console.log(`2. NFTProtect2:`);
            await setNFTProtectRequestHub();
            await setNFTProtectUserRegistry();
            await setTechnicalOwner();
            const nftProtect = await registerProtectorFactory();
            console.log(`NFTProtect2 ${nftProtect.address} configured successfully`);
            console.log(`3. UserRegistry:`);
            await configureUserRegistryFees();
            console.log(`UserRegistry configured successfully`);
        } else {
            throw Error('No client configured')
        }
    } catch (error) {
        console.error(error);
        process.exitCode = 1;
    }
}

main();
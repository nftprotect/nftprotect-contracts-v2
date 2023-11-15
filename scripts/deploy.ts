import { formatEther, parseEther, GetContractReturnType } from "viem";
import hre from "hardhat";

const aregAddress = "0x6b5f8057679F6F35Efd1Ffb9EE90cF71f900bC38";
const didAddress = "0x06da1f111d42BDf68b5AdA620459385D5ae2E3B1";

async function deployNFTProtect2() {
  const nftProtect2 = await hre.viem.deployContract("NFTProtect2");
  return nftProtect2;
}

async function deployUserRegistry(arbitratorRegistry: GetContractReturnType, did: GetContractReturnType, nftProtect2: GetContractReturnType) {
  const userRegistry = await hre.viem.deployContract("UserRegistry", [arbitratorRegistry.address, did.address, nftProtect2.address]);
  return userRegistry;
}

async function deployRequestsHub(arbitratorRegistry: GetContractReturnType, nftProtect2: GetContractReturnType) {
  const requestsHub = await hre.viem.deployContract("RequestsHub", [arbitratorRegistry.address, nftProtect2.address]);
  return requestsHub;
}

async function deployProtectorFactory721(nftProtect2: GetContractReturnType) {
  const protectorFactory721 = await hre.viem.deployContract("ProtectorFactory721", [nftProtect2.address]);
  return protectorFactory721;
}

async function main() {
  const arbitratorRegistry = await hre.viem.getContractAt("ArbitratorRegistry", aregAddress)
  const did = await hre.viem.getContractAt("UserDIDDummyAllowAll", didAddress)
  
  const nftProtect2 = await deployNFTProtect2();
  console.log(`NFTProtect2 deployed to ${nftProtect2.address}`);

  const userRegistry = await deployUserRegistry(arbitratorRegistry, did, nftProtect2);
  console.log(`UserRegistry deployed to ${userRegistry.address}`);

  const requestsHub = await deployRequestsHub(arbitratorRegistry, nftProtect2);
  console.log(`RequestsHub deployed to ${requestsHub.address}`);

  const protectorFactory721 = await deployProtectorFactory721(nftProtect2);
  console.log(`ProtectorFactory721 deployed to ${protectorFactory721.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
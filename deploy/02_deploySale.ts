import { ethers } from "hardhat";
import { MerkleTree } from 'merkletreejs'
import keccak256 from 'keccak256'

const func: any = async function (hre: any) {

    const {deployments, getNamedAccounts} = hre;
    const {deploy} = deployments;
  
    const {deployer} = await getNamedAccounts();

    const address = 
    const NFT = await hre.ethers.getContract('CryptoSportsNFT', deployer);

    const result = await deploy('CryptoSportsMintingMgmt', {
      from: deployer,
      args: [
        [address],
        [1000],
        NFT.address
      ],
      log: true,
    });
    hre.deployments.log(
      `🚀 nft contract deployed at ${result.address} using ${result.receipt?.gasUsed} gas`
    );
  };
  
  export default func;
  func.tags = ['DeploySale'];
  func.dependencies = ['DeployNFT'];
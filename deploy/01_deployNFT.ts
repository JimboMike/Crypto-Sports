import { ethers } from "hardhat";
import { MerkleTree } from 'merkletreejs'
import keccak256 from 'keccak256'

const func: any = async function (hre: any) {

    const {deployments, getNamedAccounts} = hre;
    const {deploy} = deployments;
  
    const {deployer} = await getNamedAccounts();

    const address = 
  
    const result = await deploy('CryptoSportsNFT', {
      from: deployer,
      args: [
        'https://new-crypto-backend.vercel.app/api/v1/nfl/metadata/',
        'CryptoSportsNFL',
        'CSNFL',
        address
      ],
      log: true,
    });
    hre.deployments.log(
      `🚀 nft contract deployed at ${result.address} using ${result.receipt?.gasUsed} gas`
    );
  };
  
  export default func;
  func.tags = ['DeployNFT'];
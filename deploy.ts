import { Account, Contract } from "starknet";
import { RpcProvider } from "starknet";

const CLASS_HASH = '0x014a8192aca57f1789442116746ce9c90c130d28e7ba277a83311c465e5e0809';

const run = async () => {
    const provider = new RpcProvider({ 
        nodeUrl: 'https://starknet-sepolia.public.blastapi.io',
      });
    const account = new Account(
        provider, 
        '0x01329EDaC874bb837637D7a4eED5E1093162aBc7D7a663f05428d39A8AB9552D', 
        '0x02e13f08f7bd2e4e4cc568788bf7b03ec3995cb9fe05b30cf7a2f27e57817e7e'
      );

    const deployResponse = await account.deployContract({ 
        classHash: CLASS_HASH,

        constructorCalldata: [
            '0x078662e7352d062084b0010068b99288486c2d8b914f6e2a55ce945f8792c8b1',
            '0x078662e7352d062084b0010068b99288486c2d8b914f6e2a55ce945f8792c8b1',
        ],
      });
    
      console.log('Waiting for deployment transaction...');
      await provider.waitForTransaction(deployResponse.transaction_hash);
  
      const { abi } = await provider.getClassByHash(CLASS_HASH);
      if (!abi) {
        throw new Error('No ABI found for deployed contract');
      }
  
      const contract = new Contract(abi, deployResponse.contract_address, provider);
  
      console.log('Contract deployment successful!');    
}

run()
  .then(() => console.log('Deployment completed'))
  .catch((error) => console.error('Error during deployment:', error));
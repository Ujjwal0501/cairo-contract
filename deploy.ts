import { Account, Contract } from "starknet";
import { RpcProvider } from "starknet";

const CLASS_HASH = '0x014a8192aca57f1789442116746ce9c90c130d28e7ba277a83311c465e5e0809';

const run = async () => {
    const provider = new RpcProvider({ 
        nodeUrl: 'http://localhost:5050',
      });
    const account = new Account(
        provider, 
        '0x064b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691', 
        '0x0000000000000000000000000000000071d7bb07b9a64f6f78ac4c816aff4da9'
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
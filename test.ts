import { Account, Contract, number, shortString } from "starknet";
import { RpcProvider } from "starknet";

const CLASS_HASH = '0x014a8192aca57f1789442116746ce9c90c130d28e7ba277a83311c465e5e0809';
const CONTRACT_ADDRESS = '0x047b604c233bccca4b1d4d7bcbb10ac3ad84b24eff6b355002809020dc800cdb';

const run = async () => {
    const provider = new RpcProvider({ 
        nodeUrl: 'https://starknet-mainnet.public.blastapi.io',
      });
    const account = new Account(
        provider, 
        '0x01329EDaC874bb837637D7a4eED5E1093162aBc7D7a663f05428d39A8AB9552D', 
        'PRIVATE_KEY'
      );

      const { abi } = await provider.getClassByHash(CLASS_HASH);
      if (!abi) {
        throw new Error('No ABI found for deployed contract');
      }
  
      const contract = new Contract(abi, CONTRACT_ADDRESS, provider);
  
      contract.connect(account);
      const myCall = contract.populate('create', ['0x01329EDaC874bb837637D7a4eED5E1093162aBc7D7a663f05428d39A8AB9552D', 2, 'https://twitter.com']);

      console.log('MyCall:', myCall);

      const tx = await contract.create(myCall.calldata);
      const receipt = await provider.waitForTransaction(tx.transaction_hash);
      console.log('Transaction receipt:', receipt);
}

run()
  .then(() => console.log('Deployment completed'))
  .catch((error) => console.error('Error during deployment:', error));
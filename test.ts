import { Account, Contract, number, shortString } from "starknet";
import { RpcProvider } from "starknet";

const CLASS_HASH = '0x0474949d7bb9292b35d33603e1a2762143fffbea2785aae4bede32e2872e865a';
const CONTRACT_ADDRESS = '0x00d4ccd1ce0660056ed349d245fdec7f6ceb574ae7f867ef6e9c0db52e3feef8';

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
      const myCall = contract.populate('create', ['https://youtube.com']);

      console.log('MyCall:', myCall);

      const tx = await contract.create(myCall.calldata);
      const receipt = await provider.waitForTransaction(tx.transaction_hash);
      console.log('Transaction receipt:', receipt);
}

run()
  .then(() => console.log('Deployment completed'))
  .catch((error) => console.error('Error during deployment:', error));
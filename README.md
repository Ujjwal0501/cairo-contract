```
curl --proto '=https' --tlsv1.2 -sSf https://sh.starkup.dev | sh

scarb build
starknet-devnet --seed=0

starkli signer keystore from-key keystore.json
starkli account fetch 0x064b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691 --output=account.json --rpc=http://127.0.0.1:5050
```


```
export STARKNET_KEYSTORE=$(pwd)/keystore.json
export STARKNET_ACCOUNT=$(pwd)/account.json

starkli declare target/dev/aia_AIAssassins.contract_class.json  --rpc=http://127.0.0.1:5050
```
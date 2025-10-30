# TODO

- Add openzepplin modules for ERC20 mint 1B tokens
- Add a function to recieve ETH, 3.5 ETH 
- Add function to withdraw that funds, only Owner 
- Add uniswap modules
- Add another function that will create a uniswap v4 pool with 3.5ETH/200M Tokens  
- Check the NFT ownership of liquidity creation

TOKEN CONTRACT v4 

- Deploy Token 
```
forge script script/DeployTokenV4.s.sol:DeployTokenV4 --rpc-url $SEPOLIA_RPC_URL --account dev --sender 0x8fe6509e8e7954b4848772e989829a958805a2b4  --broadcast
```

- Update the env with token address. 


- Deposit 3.5 ETH 

```
forge script script/InteractTokenV4.s.sol:InteractTokenV4 --sig 'sendETH()'  --rpc-url $SEPOLIA_RPC_URL --account dev --sender 0x8fe6509e8e7954b4848772e989829a958805a2b4  --broadcast
```

- Create Pool

```
forge script script/InteractTokenV4.s.sol:InteractTokenV4 --sig 'createPool()'  --rpc-url $SEPOLIA_RPC_URL --account dev --sender 0x8fe6509e8e7954b4848772e989829a958805a2b4  --broadcast
```

- To withdraw funds 

```
forge script script/InteractTokenV4.s.sol:InteractTokenV4 --sig 'withdraw()'  --rpc-url $SEPOLIA_RPC_URL --account dev --sender 0x8fe6509e8e7954b4848772e989829a958805a2b4  --broadcast
```

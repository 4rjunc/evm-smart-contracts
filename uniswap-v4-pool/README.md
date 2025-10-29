# TODO

- Add openzepplin modules for ERC20 mint 1B tokens
- Add a function to recieve ETH, 3.5 ETH 
- Add function to withdraw that funds, only Owner 
- Add uniswap modules
- Add another function that will create a uniswap v4 pool with 3.5ETH/200M Tokens  
- Check the NFT ownership of liquidity creation

- Deploy Token 
```
forge script script/DeployToken.s.sol:DeployToken --rpc-url $SEPOLIA_RPC_URL --account dev --broadcast
```

- Interact Token, Deposit 3.5 ETH 
```
forge script script/InteractToken.s.sol:InteractToken --rpc-url $SEPOLIA_RPC_URL --account dev --broadcast
```

- Withdraw 3.5 ETH Deposit 
```
forge script script/InteractToken.s.sol:InteractToken --sig "withdraw()" --rpc-url $SEPOLIA_RPC_URL --account dev --broadcast
```



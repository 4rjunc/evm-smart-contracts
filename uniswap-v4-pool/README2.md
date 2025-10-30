# Token Contract with ETH Management

This is a Foundry project for an ERC20 token contract with ETH receiving and withdrawal functionality.

## Features Implemented (Points 1-3)

✅ **Point 1**: ERC20 token with OpenZeppelin - mints 1 Billion tokens to deployer
✅ **Point 2**: Function to receive exactly 3.5 ETH
✅ **Point 3**: Owner-only withdrawal functions

## Setup Instructions

### 1. Install Foundry (if not already installed)
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. Create a new Foundry project
```bash
forge init token-project
cd token-project
```

### 3. Install OpenZeppelin Contracts
```bash
forge install OpenZeppelin/openzeppelin-contracts
```

### 4. Update foundry.toml
Add this to your `foundry.toml`:
```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
remappings = [
    "@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/"
]

[rpc_endpoints]
sepolia = "${SEPOLIA_RPC_URL}"
```

### 5. Copy the contract files
- Copy `TokenContract.sol` to `src/TokenContract.sol`
- Copy `DeployToken.s.sol` to `script/DeployToken.s.sol`
- Copy `InteractToken.s.sol` to `script/InteractToken.s.sol`

### 6. Create .env file
Create a `.env` file in the project root:
```bash
PRIVATE_KEY=your_private_key_here
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR-API-KEY
ETHERSCAN_API_KEY=your_etherscan_api_key
TOKEN_ADDRESS=deployed_contract_address_here
```

**Important**: Add `.env` to your `.gitignore`!

### 7. Load environment variables
```bash
source .env
```

## Deployment & Usage

### Deploy to Sepolia Testnet

```bash
forge script script/DeployToken.s.sol:DeployToken \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --verify \
    -vvvv
```

After deployment:
1. Copy the deployed contract address from the output
2. Add it to your `.env` file as `TOKEN_ADDRESS=0x...`

### Send 3.5 ETH to Contract

```bash
# Make sure you have TOKEN_ADDRESS in .env
forge script script/InteractToken.s.sol:InteractToken \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    -vvvv
```

### Withdraw ETH (Owner Only)

```bash
forge script script/InteractToken.s.sol:InteractToken \
    --sig "withdraw()" \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    -vvvv
```

## Testing Locally

### Compile
```bash
forge build
```

### Run Tests
```bash
forge test -vvv
```

### Deploy to Local Anvil
```bash
# Terminal 1: Start Anvil
anvil

# Terminal 2: Deploy
forge script script/DeployToken.s.sol:DeployToken \
    --rpc-url http://localhost:8545 \
    --broadcast
```

## Contract Functions

### TokenContract

**Constructor**
- Mints 1 billion tokens to the deployer
- Sets the deployer as owner

**receiveETH()**
- Accepts exactly 3.5 ETH
- Can only be called once
- Emits `ETHReceived` event

**withdrawETH(uint256 amount)**
- Owner-only function
- Withdraws specified amount of ETH
- Emits `ETHWithdrawn` event

**withdrawAllETH()**
- Owner-only function
- Withdraws all ETH from contract
- Emits `ETHWithdrawn` event

**getETHBalance()**
- View function
- Returns contract's ETH balance

## Security Features

- Uses OpenZeppelin's battle-tested ERC20 and Ownable contracts
- Prevents direct ETH transfers (must use `receiveETH()`)
- Owner-only withdrawal protection
- Reentrancy protection via checks-effects-interactions pattern

## Gas Optimization Tips

- Token transfers are optimized by OpenZeppelin
- Withdrawal uses low-level `call` for gas efficiency

## Next Steps (Points 4-5)

Once these 3 points are working, we'll add:
- ✏️ Uniswap V4 integration modules
- ✏️ Pool creation function with 3.5 ETH / 200M tokens
- ✏️ Liquidity NFT ownership tracking

## Troubleshooting

**Issue**: "Insufficient funds for gas"
- **Solution**: Make sure your wallet has enough ETH for gas fees (+ 3.5 ETH if calling receiveETH)

**Issue**: "ETH already received"
- **Solution**: The contract can only receive 3.5 ETH once. If testing, redeploy the contract.

**Issue**: "Ownable: caller is not the owner"
- **Solution**: Make sure you're calling withdraw functions with the same address that deployed the contract.

## Get Testnet ETH

Sepolia Faucets:
- https://sepoliafaucet.com/
- https://www.alchemy.com/faucets/ethereum-sepolia
- https://faucet.quicknode.com/ethereum/sepolia

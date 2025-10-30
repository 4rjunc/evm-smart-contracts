# 🦄 Uniswap V4 Integration - Line by Line Explanation

## 📚 What We're Building

Creating a pool where people can trade: **MTK Token ↔ ETH**
- Pool will have: 200M tokens + 3.5 ETH
- Trading fee: 0.30%
- Full range liquidity (works at all prices)

---

## 🔑 Key Concepts Explained

### 1. **PoolKey** - The Pool's Identity Card

```solidity
PoolKey memory poolKey = PoolKey({
    currency0: currency0,      // First token (must be lower address)
    currency1: currency1,      // Second token (must be higher address)
    fee: 3000,                 // 0.30% fee
    tickSpacing: 60,           // Price precision
    hooks: address(0)          // No custom behavior
});
```

**What each field means:**

- **currency0 & currency1**: The two tokens in the pool
  - MUST be sorted by address (lower address first)
  - ETH address = `0x0000...0000`
  - Your token address = `0xABC123...` (example)
  - Whoever has lower address becomes currency0

- **fee**: Trading fee in "pips" (parts per million)
  - 3000 = 3000/1,000,000 = 0.003 = 0.30%
  - Common values: 500 (0.05%), 3000 (0.30%), 10000 (1%)

- **tickSpacing**: How granular prices can be
  - 60 is standard for 0.30% pools
  - Lower = more precise but more expensive to trade
  - Think of it like decimal places for prices

- **hooks**: Custom smart contract for special behavior
  - `address(0)` = no hooks = standard pool
  - Advanced: Could add fees, limits, etc.

---

### 2. **sqrtPriceX96** - The Starting Price

```solidity
uint160 sqrtPriceX96 = 1897569893128809606502511493120;
```

**What is this number?**

This is the starting price, encoded in a special format:
- Formula: `sqrt(price) * 2^96`
- `2^96` = a very large number for precision
- Price = how many token1 per 1 token0

**For your pool:**
- You have: 200M tokens = 3.5 ETH
- So: 1 ETH = 200M / 3.5 = 57,142,857 tokens
- This is your starting price!

**Why square root?**
Uniswap uses a mathematical trick (concentrated liquidity) that requires square root of price for efficiency.

**How to calculate:**
```python
# Python example
import math

tokens_per_eth = 57_142_857
sqrt_price = math.sqrt(tokens_per_eth)
sqrtPriceX96 = int(sqrt_price * (2**96))
print(sqrtPriceX96)
# Output: 1897569893128809606502511493120
```

---

### 3. **Ticks** - Price Ranges

```solidity
int24 tickLower = -887220;  // Minimum tick
int24 tickUpper = 887220;   // Maximum tick
```

**What are ticks?**
- Ticks represent discrete price points
- Each tick = a specific price level
- Your liquidity is active between tickLower and tickUpper

**Full range liquidity:**
- -887220 to 887220 = maximum possible range
- Means: liquidity works at ALL prices
- Simpler but less capital efficient

**Custom ranges (advanced):**
- You could set smaller range, like -1000 to 1000
- More capital efficient
- But liquidity inactive outside range

---

### 4. **Liquidity** - How Much to Add

```solidity
uint128 liquidity = 1000000 * 10**18;
```

**What is liquidity?**
- NOT the same as token amount!
- It's "liquidity units" - a mathematical representation
- Formula: `L = sqrt(x * y)` where x=tokens, y=ETH

**How to calculate properly:**
You need a helper library (LiquidityAmounts.sol) that converts:
- Token amounts (200M tokens, 3.5 ETH) 
- → Liquidity units

**For now:**
We used a placeholder. In production, you'd calculate exact liquidity units.

---

### 5. **Actions** - Commands to Execute

```solidity
bytes memory actions = abi.encodePacked(
    uint8(Actions.MINT_POSITION),  // Command 1: Create position
    uint8(Actions.SETTLE_PAIR)     // Command 2: Pay tokens
);
```

**What are actions?**
- Uniswap V4 uses a command system
- You encode multiple commands to execute in sequence

**Our commands:**
1. **MINT_POSITION**: Create a new liquidity position
   - Gives you an ERC-721 NFT representing your liquidity
   - The NFT proves you own this liquidity

2. **SETTLE_PAIR**: Pay the required tokens
   - Tells Uniswap: "Take my tokens and ETH"
   - Actually transfers 200M tokens + 3.5 ETH to the pool

---

### 6. **Permit2** - Token Approval System

```solidity
// Step 1: Approve Permit2
_approve(address(this), permit2, POOL_TOKENS);

// Step 2: Approve PositionManager through Permit2
IAllowanceTransfer(permit2).approve(
    address(this),       // token
    positionManager,     // spender
    uint160(POOL_TOKENS),// amount
    uint48(block.timestamp + 3600) // expiration
);
```

**What is Permit2?**
- A better token approval system by Uniswap
- More gas efficient
- Has expiration dates (safer)

**Why two approvals?**
1. First: Let Permit2 move your tokens
2. Second: Let PositionManager use Permit2 to move your tokens

Think of it like: 
- Step 1: Give keys to security guard
- Step 2: Security guard gives keys to the driver

---

### 7. **Multicall** - Execute Multiple Operations

```solidity
bytes[] memory params = new bytes[](2);

params[0] = abi.encodeWithSelector(...); // Initialize pool
params[1] = abi.encodeWithSelector(...); // Add liquidity

IPositionManager(positionManager).multicall{value: REQUIRED_ETH}(params);
```

**What is multicall?**
- Execute multiple functions in 1 transaction
- Saves gas
- Atomic: either all succeed or all fail

**Our multicall:**
1. **params[0]**: Create the pool (initialize it)
2. **params[1]**: Add liquidity to the pool

**Why send ETH?**
- `{value: REQUIRED_ETH}` sends 3.5 ETH with the transaction
- Needed because we're adding ETH to the pool

---

## 🎯 Flow Summary

```
1. Receive 3.5 ETH
   └─> Contract now has: 1B tokens + 3.5 ETH

2. Owner calls createUniswapPool()
   ├─> Step 1: Configure pool (PoolKey)
   ├─> Step 2: Calculate starting price (sqrtPriceX96)
   ├─> Step 3: Approve tokens (Permit2)
   ├─> Step 4: Encode multicall
   │   ├─> params[0]: Initialize pool
   │   └─> params[1]: Add 200M tokens + 3.5 ETH
   └─> Step 5: Execute multicall
       └─> Result: Pool created! NFT received!

3. Pool is now live on Uniswap V4
   └─> People can trade MTK ↔ ETH
```

---

## 📊 What You Get

After calling `createUniswapPool()`:

✅ **Uniswap V4 pool created**
- Traders can swap MTK ↔ ETH
- You earn 0.30% fees on every trade

✅ **ERC-721 NFT received**
- Token ID stored in `positionTokenId`
- Proves you own the liquidity
- Can be transferred or sold

✅ **Your balances:**
- Started: 1B tokens + 3.5 ETH
- After pool: 800M tokens + 0 ETH
- In pool: 200M tokens + 3.5 ETH

---

## 🔧 Important Numbers Reference

| Variable | Value | Meaning |
|----------|-------|---------|
| `fee` | 3000 | 0.30% trading fee |
| `tickSpacing` | 60 | Standard for 0.30% |
| `tickLower` | -887220 | Min price (full range) |
| `tickUpper` | 887220 | Max price (full range) |
| `sqrtPriceX96` | 189756... | Starting price encoded |
| `POOL_TOKENS` | 200M | Tokens for the pool |
| `REQUIRED_ETH` | 3.5 ETH | ETH for the pool |

---

## ⚠️ Important Notes

1. **Contract needs to own tokens**
   - Changed `_mint(msg.sender, ...)` to `_mint(address(this), ...)`
   - Contract needs tokens to create pool

2. **Addresses needed**
   - `poolManager`: Uniswap V4 core contract
   - `positionManager`: Liquidity manager
   - `permit2`: Token approval system
   - These are different per network (mainnet, Sepolia, etc.)

3. **One-time operation**
   - `poolCreated` prevents calling twice
   - Can't create the same pool again

4. **NFT ownership**
   - The contract receives the liquidity NFT
   - To remove liquidity, you need this NFT
   - Token ID stored in `positionTokenId`

---

## 🚀 Next Steps

1. Get the Uniswap V4 contract addresses for your network
2. Update constructor parameters
3. Deploy contract
4. Send 3.5 ETH
5. Call `createUniswapPool()`
6. Pool is live! 🎉

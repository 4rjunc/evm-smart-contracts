TOKEN CONTRACT v4 

# 📘 Understanding Uniswap V4 Pool Creation - Complete Guide

## 🎯 Overview

This guide explains how to programmatically create a Uniswap V4 liquidity pool from a solidity smart contract. 

I'll break down every line of code in the `createUniswapPool()` function.

---

## 🔑 Core Uniswap V4 Concepts

- **PoolManager**:  Handles pool initialization, swaps, and liquidity modifications
- **PositionManager**: A peripheral contract that simplifies liquidity position management, Returns an ERC-721 NFT that represents your liquidity position
- **Permit2**: Manages token permissions. Like a secure "vault manager" for token permissions

## 🏊 Pool Configuration Parameters

- **PoolKey**

**Definition:** A unique identifier for a Uniswap pool

```solidity
struct PoolKey {
    Currency currency0;    // first token (lower address)
    Currency currency1;    // second token (higher address)
    uint24 fee;           // trading fee 
    int24 tickSpacing;    // minimum tick movement
    IHooks hooks;         // optional custom hook contract
}
```

**Components:**

#### **currency0 & currency1**
- Must be sorted by address (currency0 < currency1)
- `address(0)` = native ETH
- **Why?:** Ensures pool uniqueness - prevents duplicate pools


#### **fee**
- The swap fee traders pay
- In hundredths of a basis point (bip)
- **Calculation:** `fee / 1,000,000 = percentage`

**Common values:**
| Fee Value | Percentage | Use Case |
|-----------|------------|----------|
| 500 | 0.05% | Stablecoin pairs |
| 3000 | 0.30% | Standard pairs |
| 10000 | 1.00% | Exotic pairs |


#### **tickSpacing**
- The minimum distance between usable ticks
- Defines price granularity and gas efficiency
- **Trade-off:** 
  - Smaller spacing = More precise prices, but higher gas costs
  - Larger spacing = Less precise, but cheaper swaps

**Common pairings:**
| Fee | Typical TickSpacing |
|-----|---------------------|
| 0.05% | 10  |
| 0.30% | 60  |
| 1.00% | 200 |

#### **hooks**
- An optional smart contract that can execute custom logic
- Runs Before/after swaps, liquidity changes, etc.
- **Use cases:** 
  - Custom fees
  - Trading limits
  - Oracles
  - Gamification

---

## 📊 Price & Tick System

### 5. **Starting Price (sqrtPriceX96)**

**The most confusing but important parameter!**

#### **What is it?**
A special encoding of the pool's initial price using this formula:
```
sqrtPriceX96 = sqrt(price) × 2^96
```

#### **Why this format?**
- The `× 2^96` provides extreme decimal precision
- Square root math is cheaper for calculations
- Can represent prices from near-zero to near-infinity

#### **How to calculate it:**

**Step 1: Determine your desired price ratio**
```
Price = How many token1 per 1 token0
```

**In our code:**
```
We want: 3.5 ETH = 200M tokens
So: 1 ETH = 200M / 3.5 = 57,142,857 tokens
Price = 57,142,857 (tokens per ETH)
```

**In our code:**
```solidity
uint160 startingPrice = 501082896750095888663770159906816;
```

**Important: The starting price determines the initial exchange rate when the pool opens!**

---

### 6. **Ticks**

#### **What is a tick?**
- A **discrete price point** in the Uniswap price curve
- Each tick represents a 0.01% price change (1 basis point)
- Formula: `price = 1.0001^tick`

#### **Tick Math:**
```
Tick = 0     → Price = 1.0
Tick = 100   → Price = 1.01  (1% higher)
Tick = -100  → Price = 0.99  (1% lower)
Tick = 23028 → Price = 10    (10x higher)
```

#### **Tick Range:**
- **Minimum:** -887272
- **Maximum:** 887272
- **Range span:** Covers prices from ~0 to ~infinity

---

### 7. **tickLower & tickUpper**

**Definition:** The price range where your liquidity is active

```solidity
int24 tickLower;  // Lower boundary
int24 tickUpper;  // Upper boundary
```

#### **Concentrated Liquidity Concept:**
- Your liquidity only works between these two ticks
- If price moves outside this range → Your liquidity becomes inactive

#### **In our code:**
```solidity
int24 currentTick = TickMath.getTickAtSqrtPrice(startingPrice);

int24 tickLower = truncateTickSpacing(
    (currentTick - 750 * tickSpacing), 
    tickSpacing
);

int24 tickUpper = truncateTickSpacing(
    (currentTick + 750 * tickSpacing), 
    tickSpacing
);
```

#### **Rule:** Ticks must be multiples of tickSpacing!
```solidity
function truncateTickSpacing(int24 tick, int24 tickSpacing) internal pure returns (int24) {
    return ((tick / tickSpacing) * tickSpacing);
}
```

---

### 8. **Liquidity**

#### **What is liquidity?**
- **NOT** simply "amount of tokens"
- It's a mathematical representation combining BOTH assets
- Formula: `L = sqrt(x × y)` where x=token0, y=token1

#### **Why this matters:**
- Different tick ranges need different liquidity values
- Uniswap uses this to calculate how much of each token is needed

#### **Calculation:**
```solidity
uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
    startingPrice,        // current price
    TickMath.getSqrtPriceAtTick(tickLower),  // lower boundary price
    TickMath.getSqrtPriceAtTick(tickUpper),  // upper boundary price
    token0Amount,         // 3.5 ETH
    token1Amount          // 200M tokens
);
```

**What this does:**
1. Converts tick boundaries to prices
2. Calculates optimal liquidity value
3. Ensures both assets are utilized efficiently within the range

**Result:** A `uint128` number representing "liquidity units"

---

## 🔨 Step-by-Step Pool Creation Process

let's understand the `createUniswapPool()` function line by line:

### **Step 0: Prerequisites**
```solidity
require(ethReceived, "Must receive ETH first");
require(!poolCreated, "Pool already created");
require(address(this).balance >= REQUIRED_ETH, "Insufficient ETH");

poolCreated = true;
```
**Purpose:** Safety checks to ensure contract has funds and pool isn't duplicated

---

### **Step 1: Define Currencies**
```solidity
Currency ethCurrency = Currency.wrap(address(0));
Currency tokenCurrency = Currency.wrap(address(this));

Currency currency0 = ethCurrency;
Currency currency1 = tokenCurrency;
```

**What's happening:**
- Wrap addresses into `Currency` type (Uniswap's format)
- ETH always has lower address (0x000...) so it's currency0
- Our token is currency1

---

### **Step 2: Set Pool Parameters**
```solidity
int24 tickSpacing = 60;
uint160 startingPrice = 501082896750095888663770159906816;
uint256 token0Amount = 3.5 ether;
uint256 token1Amount = 200_000_000e18;
```

**What's happening:**
- Define tick granularity (60 = standard for 0.30% fee)
- Set initial price (encoded as sqrtPriceX96)
- Specify how much of each asset to deposit

---

### **Step 3: Create PoolKey**
```solidity
PoolKey memory poolKey = PoolKey({
    currency0: currency0,      // ETH
    currency1: currency1,      // our token
    fee: 3000,                 // 0.30% fee
    tickSpacing: 60,           // price steps
    hooks: IHooks(address(0))  // no hooks
});
```

**What's happening:**
- Unique identifier for this pool
- This combination creates a deterministic pool address

---

### **Step 4: Set Slippage Protection**
```solidity
uint256 amount0Max = token0Amount + 1;  // 3.5 ETH + 1 wei
uint256 amount1Max = token1Amount + 1;  // 200M + 1 token
```

**What's happening:**
- Set maximum amounts we're willing to deposit
- The "+1" provides tiny buffer for rounding

---

### **Step 5: Approve Tokens via Permit2**
```solidity
_approve(address(this), permit2, token1Amount);

IAllowanceTransfer(permit2).approve(
    address(this),           // Token to approve
    positionManager,         // Spender
    uint160(amount1Max),     // Amount
    uint48(block.timestamp + 3600)  // Expires in 1 hour
);
```

**What's happening:**
1. **First approval:** Contract approves Permit2 to move tokens
2. **Second approval:** Permit2 approves PositionManager to move tokens
3. **Why two steps?** Permit2 acts as secure intermediary

**Visual:**
```
Contract → [Permit2] → PositionManager → Pool
         (approval 1)  (approval 2)
```

---

### **Step 6: Prepare Multicall Parameters**
```solidity
bytes[] memory params = new bytes[](2);
```

**What's happening:**
- Multicall lets us execute multiple operations atomically
- We'll do 2 operations: (1) Initialize pool, (2) Add liquidity

---

### **Step 7: Encode Pool Initialization**
```solidity
params[0] = abi.encodeWithSelector(
    IPoolInitializer_v4.initializePool.selector,
    poolKey,
    startingPrice
);
```

**What's happening:**
- Prepare the call to create the pool
- `initializePool` sets up the pool with our starting price
- This reserves the pool - it exists but has no liquidity yet

---

### **Step 8: Prepare Action Commands**
```solidity
bytes memory actions = abi.encodePacked(
    uint8(Actions.MINT_POSITION),  // command 1
    uint8(Actions.SETTLE_PAIR)     // command 2
);
```

**What's happening:**
- Uniswap V4 uses a command system
- `MINT_POSITION`: Create a new liquidity position (get NFT)
- `SETTLE_PAIR`: Pay the required tokens to fund the position

**Order matters:**
1. First: Create position
2. Then: Pay for it

---

### **Step 9: Calculate Tick Range**
```solidity
int24 currentTick = TickMath.getTickAtSqrtPrice(startingPrice);

int24 tickLower = truncateTickSpacing(
    (currentTick - 750 * tickSpacing), 
    tickSpacing
);

int24 tickUpper = truncateTickSpacing(
    (currentTick + 750 * tickSpacing), 
    tickSpacing
);
```

**What's happening:**
1. Convert price to tick number
2. Set lower bound: 750 tick spacings below
3. Set upper bound: 750 tick spacings above
4. Truncate to ensure they're valid multiples

**Result:** Liquidity active for ~1.5x price movement in either direction

---

### **Step 10: Calculate Required Liquidity**
```solidity
uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
    startingPrice,
    TickMath.getSqrtPriceAtTick(tickLower),
    TickMath.getSqrtPriceAtTick(tickUpper),
    token0Amount,
    token1Amount
);
```

**What's happening:**
- Uniswap calculates how much "liquidity" to create
- Based on: current price, range, and token amounts
- This determines the actual deposit amounts

**Output:** A `uint128` representing liquidity units

---

### **Step 11: Encode Mint Parameters**
```solidity
bytes[] memory mintParams = new bytes[](2);

mintParams[0] = abi.encode(
    poolKey,        // which pool
    tickLower,      // lower bound of range
    tickUpper,      // upper bound of range
    liquidity,      // how much liquidity
    amount0Max,     // max ETH willing to pay
    amount1Max,     // max tokens willing to pay
    msg.sender,     // who gets the NFT
    ""              // no hook data
);

mintParams[1] = abi.encode(
    poolKey.currency0,  // settle ETH
    poolKey.currency1   // settle tokens
);
```

**What's happening:**
- **mintParams[0]:** Details about the position to create
- **mintParams[1]:** Which currencies to settle (pay)

**Important: `msg.sender` receives the ERC-721 NFT representing this position!**

---

### **Step 12: Encode Liquidity Modification**
```solidity
uint256 deadline = block.timestamp + 3600;

params[1] = abi.encodeWithSelector(
    IPositionManager.modifyLiquidities.selector,
    abi.encode(actions, mintParams),
    deadline
);
```

**What's happening:**
- Encode the liquidity addition operation
- Include deadline (transaction must execute within 1 hour)
- Packages our actions and parameters

---

### **Step 13: Execute Multicall**
```solidity
bytes[] memory results = IPositionManager(positionManager).multicall{
    value: amount0Max  // Send ETH along with call
}(params);
```

**What's happening:**
1. Send ETH to PositionManager
2. Execute both operations atomically:
   - **params[0]:** Initialize pool
   - **params[1]:** Add liquidity
3. Receive results array

**Atomic execution means:**
- Both succeed together, or
- Both fail together
- No partial execution!

---

## 🎯 What Actually Happens On-Chain

When `createUniswapPool()` executes:

### **Transaction Flow:**

```
1. Contract checks prerequisites
   ↓
2. Approve tokens via Permit2
   ↓
3. Call PositionManager.multicall() with ETH
   ↓
4. PositionManager delegates to PoolManager
   ↓
5. PoolManager.initialize() creates pool
   ├─ Stores PoolKey
   ├─ Sets starting price
   └─ Emits Initialize event
   ↓
6. PoolManager.modifyLiquidity() adds liquidity
   ├─ Transfers ETH to pool
   ├─ Transfers tokens to pool
   ├─ Mints position NFT to msg.sender
   └─ Emits ModifyLiquidity event
   ↓
7. Pool is now live and tradeable!
```

### **State Changes:**

**PoolManager:**
- New pool registered with unique ID
- Pool state: initialized, price set, liquidity added

**Your Contract:**
- ETH balance: -3.5 ETH
- Token balance: -200M tokens

**msg.sender (caller):**
- Receives ERC-721 NFT
- NFT ID represents this specific position
- Can use NFT to remove liquidity later

**The Pool:**
- Now contains: 3.5 ETH + 200M tokens
- Ready for traders to swap
- LP earns 0.30% on every trade

---

## 📊 Complete Parameter Summary

| Parameter | Value | Meaning |
|-----------|-------|---------|
| **currency0** | 0x000...000 | ETH (native) |
| **currency1** | Contract address | Our token |
| **fee** | 3000 | 0.30% trading fee |
| **tickSpacing** | 60 | 0.01% price steps |
| **hooks** | address(0) | No custom logic |
| **startingPrice** | 5.01e32 | Initial exchange rate |
| **tickLower** | ~130052 | Lower price bound |
| **tickUpper** | ~220052 | Upper price bound |
| **liquidity** | Calculated | Liquidity units |
| **amount0Max** | 3.5 ETH + 1 | Max ETH to deposit |
| **amount1Max** | 200M + 1 | Max tokens to deposit |

---

## Commands to run the scripts

- Deploy Token 
```
forge script script/DeployTokenV4.s.sol:DeployTokenV4 --rpc-url $SEPOLIA_RPC_URL --account dev --sender <SENDER_ADDRESS>  --broadcast
```

- Update the env with token address. 


- Deposit 3.5 ETH 

```
forge script script/InteractTokenV4.s.sol:InteractTokenV4 --sig 'sendETH()'  --rpc-url $SEPOLIA_RPC_URL --account dev --sender <SENDER_ADDRESS>  --broadcast
```

- Create Pool

```
forge script script/InteractTokenV4.s.sol:InteractTokenV4 --sig 'createPool()'  --rpc-url $SEPOLIA_RPC_URL --account dev --sender <SENDER_ADDRESS>  --broadcast
```

- To withdraw funds, if you dont want to create the pool

```
forge script script/InteractTokenV4.s.sol:InteractTokenV4 --sig 'withdraw()'  --rpc-url $SEPOLIA_RPC_URL --account dev --sender <SENDER_ADDRESS>  --broadcast

```



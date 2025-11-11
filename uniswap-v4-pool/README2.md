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

# 📘 Understanding Uniswap V4 Pool Creation - Complete Guide

## 🎯 Overview

This guide explains how to programmatically create a Uniswap V4 liquidity pool from a solidity smart contract. 

I'll break down every line of code in the `createUniswapPool()` function.

---

## 🔑 Core Uniswap V4 Concepts

- **PoolManager**:  Handles pool initialization, swaps, and liquidity modifications
- **PositionManager**: A peripheral contract that simplifies liquidity position management
- **Role:** 
- **Think of it as:** The "interface" that makes interacting with PoolManager easier
- **Key feature:** Returns an ERC-721 NFT that represents your liquidity position
- **In our code:** `address public immutable positionManager`

### 3. **Permit2**
- **What it is:** Uniswap's advanced token approval system
- **Role:** Manages token permissions with better security and gas efficiency
- **Benefits:** 
  - Expiring approvals (safer than infinite approvals)
  - Batch approvals (save gas)
  - Signature-based approvals (no transaction needed)
- **Think of it as:** A secure "vault manager" for token permissions
- **In our code:** `address public immutable permit2`

---

## 🏊 Pool Configuration Parameters

### 4. **PoolKey**
**Definition:** A unique identifier for a Uniswap pool

```solidity
struct PoolKey {
    Currency currency0;    // First token (lower address)
    Currency currency1;    // Second token (higher address)
    uint24 fee;           // Trading fee in hundredths of a bip
    int24 tickSpacing;    // Minimum tick movement
    IHooks hooks;         // Optional custom hook contract
}
```

**Components:**

#### **currency0 & currency1**
- **Rule:** Must be sorted by address (currency0 < currency1)
- **ETH representation:** `address(0)` = native ETH
- **Why sorted?** Ensures pool uniqueness - prevents duplicate pools

**In our example:**
```solidity
Currency currency0 = Currency.wrap(address(0));        // ETH (address 0)
Currency currency1 = Currency.wrap(address(this));     // Our token
```

#### **fee**
- **What it is:** The swap fee traders pay
- **Format:** In hundredths of a basis point (bip)
- **Calculation:** `fee / 1,000,000 = percentage`

**Common values:**
| Fee Value | Percentage | Use Case |
|-----------|------------|----------|
| 500 | 0.05% | Stablecoin pairs |
| 3000 | 0.30% | Standard pairs |
| 10000 | 1.00% | Exotic pairs |

**In our example:**
```solidity
fee: 3000  // 0.30% fee
```

#### **tickSpacing**
- **What it is:** The minimum distance between usable ticks
- **Purpose:** Defines price granularity and gas efficiency
- **Trade-off:** 
  - Smaller spacing = More precise prices, but higher gas costs
  - Larger spacing = Less precise, but cheaper swaps

**Common pairings:**
| Fee | Typical TickSpacing |
|-----|---------------------|
| 0.05% | 10 |
| 0.30% | 60 |
| 1.00% | 200 |

**In our example:**
```solidity
int24 tickSpacing = 60;  // Standard for 0.30% fee pools
```

#### **hooks**
- **What it is:** An optional smart contract that can execute custom logic
- **When it runs:** Before/after swaps, liquidity changes, etc.
- **Use cases:** 
  - Custom fees
  - Trading limits
  - Oracles
  - Gamification
- **In our example:** `IHooks(address(0))` = No hooks

---

## 📊 Price & Tick System

### 5. **Starting Price (sqrtPriceX96)**

**The most confusing but crucial parameter!**

#### **What is it?**
A special encoding of the pool's initial price using this formula:
```
sqrtPriceX96 = sqrt(price) × 2^96
```

#### **Why this format?**
- **Precision:** The `× 2^96` provides extreme decimal precision
- **Efficiency:** Square root math is cheaper for calculations
- **Range:** Can represent prices from near-zero to near-infinity

#### **How to calculate it:**

**Step 1: Determine your desired price ratio**
```
Price = How many token1 per 1 token0
```

**In our example:**
```
We want: 3.5 ETH = 200M tokens
So: 1 ETH = 200M / 3.5 = 57,142,857 tokens
Price = 57,142,857 (tokens per ETH)
```

**Step 2: Calculate sqrtPriceX96**
```python
import math

price = 57_142_857
sqrt_price = math.sqrt(price)  # 7559.289...
sqrtPriceX96 = int(sqrt_price * (2**96))
# Result: 598593874676037306090487096320
```

**In our code:**
```solidity
uint160 startingPrice = 501082896750095888663770159906816;
// This represents: 1 ETH ≈ 1 Billion tokens (NOT our target!)
// NOTE: The comment says we want different ratio, but code uses this value
```

**⚠️ Important:** The starting price determines the initial exchange rate when the pool opens!

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
- **Benefit:** More capital efficient than full-range liquidity

#### **Visual Example:**
```
Price too low    Active Range         Price too high
     ↓          ↓              ↓              ↓
|---------|=============|current|=============|---------|
        tickLower              price       tickUpper
        
In range: Your liquidity earns fees ✅
Out of range: Your liquidity is idle ❌
```

#### **In our code:**
```solidity
int24 currentTick = TickMath.getTickAtSqrtPrice(startingPrice);
// Gets the tick that corresponds to our starting price
// Result: ~175052

int24 tickLower = truncateTickSpacing(
    (currentTick - 750 * tickSpacing), 
    tickSpacing
);
// = 175052 - 750*60 = 175052 - 45000 = 130052

int24 tickUpper = truncateTickSpacing(
    (currentTick + 750 * tickSpacing), 
    tickSpacing
);
// = 175052 + 750*60 = 175052 + 45000 = 220052
```

**What this means:**
- Range: **1,500 tick spacings** (750 below + 750 above)
- Price coverage: **~1.5x to ~0.67x** from starting price
- If you pick narrow range: More fees per unit, but risks going out of range
- If you pick wide range: Less fees per unit, but always active

#### **Rule:** Ticks must be multiples of tickSpacing!
```solidity
function truncateTickSpacing(int24 tick, int24 tickSpacing) internal pure returns (int24) {
    return ((tick / tickSpacing) * tickSpacing);
}
// This "rounds down" to nearest valid tick
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
    startingPrice,        // Current price
    TickMath.getSqrtPriceAtTick(tickLower),  // Lower boundary price
    TickMath.getSqrtPriceAtTick(tickUpper),  // Upper boundary price
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

Now let's walk through the `createUniswapPool()` function line by line:

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
    currency1: currency1,      // Our token
    fee: 3000,                 // 0.30% fee
    tickSpacing: 60,           // Price steps
    hooks: IHooks(address(0))  // No hooks
});
```

**What's happening:**
- Assemble the unique identifier for this pool
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
- Protects against frontrunning or price manipulation

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
    uint8(Actions.MINT_POSITION),  // Command 1
    uint8(Actions.SETTLE_PAIR)     // Command 2
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
    poolKey,        // Which pool
    tickLower,      // Lower bound of range
    tickUpper,      // Upper bound of range
    liquidity,      // How much liquidity
    amount0Max,     // Max ETH willing to pay
    amount1Max,     // Max tokens willing to pay
    msg.sender,     // Who gets the NFT
    ""              // No hook data
);

mintParams[1] = abi.encode(
    poolKey.currency0,  // Settle ETH
    poolKey.currency1   // Settle tokens
);
```

**What's happening:**
- **mintParams[0]:** Details about the position to create
- **mintParams[1]:** Which currencies to settle (pay)

**Important:** `msg.sender` receives the ERC-721 NFT representing this position!

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

### **Step 14: (Optional) Decode Position NFT ID**
```solidity
// Commented out in current code:
// positionTokenId = abi.decode(results[1], (uint256));
// emit PoolCreated(address(poolManager), positionTokenId);
```

**What this would do:**
- Extract the NFT token ID from results
- This NFT represents ownership of the liquidity position
- Can be used later to modify or remove liquidity

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

## ⚠️ Important Notes

### **1. Starting Price Matters!**
The `startingPrice` in the code (5.01e32) doesn't match the comment's intention. Always verify your sqrtPriceX96 calculation matches your desired ratio!

### **2. Tick Range Strategy**
- **Narrow range:** More fees, higher risk of going out of range
- **Wide range:** Less fees, but always active
- **Full range:** -887220 to 887220 (never inactive)

### **3. Slippage Protection**
The `amount0Max` and `amount1Max` protect you from:
- Frontrunning attacks
- Price manipulation
- Calculation errors

### **4. NFT Ownership**
The position NFT goes to `msg.sender` (the function caller), NOT the contract. Make sure the right address calls this function!

### **5. Gas Costs**
Pool creation is expensive (~400k-500k gas). Make sure you have enough ETH for:
- Pool creation transaction
- The 3.5 ETH liquidity deposit

---

## 🎓 Key Takeaways

1. **PoolKey uniquely identifies a pool** - Same pair with different fee = different pool
2. **sqrtPriceX96 sets initial price** - Must be calculated correctly
3. **Tick range defines where liquidity is active** - Choose wisely based on strategy
4. **Liquidity is NOT just token amounts** - It's a mathematical representation
5. **Multicall executes atomically** - Pool creation and liquidity addition happen together
6. **Position NFT represents ownership** - Don't lose it if you want to remove liquidity later!

---

## 🚀 Next Steps

After creating your pool:
- Monitor the position on Uniswap interface
- Track trading volume and fees earned
- Adjust range if price moves out of bounds (requires new position)
- Remove liquidity when desired using the NFT

**Congratulations! You now understand Uniswap V4 pool creation at a deep level!** 🎉

### Simple Counter Hook

## Counter.test.sol

## `setUp()` Function

```solidity
function setUp() public {
```

This runs before each test. It sets up the testing environment.

---

```solidity
deployFreshManagerAndRouters();
```

This is from the `Deployers` utility. It deploys:
- **PoolManager** - The core contract that manages all Uniswap v4 pools
- **SwapRouter** - Router contract used to execute swaps
- **ModifyLiquidityRouter** - Router for adding/removing liquidity

These are essential infrastructure contracts for Uniswap v4.

---

```solidity
hook = CounterHook(
  address(
    uint160(Hooks.AFTER_SWAP_FLAG | Hooks.BEFORE_SWAP_FLAG)
  )
);
```

This is **critical for v4 hooks**! In Uniswap v4, **the hook's address itself encodes which hook functions it implements**.

- `Hooks.AFTER_SWAP_FLAG | Hooks.BEFORE_SWAP_FLAG` - Creates a bitmask indicating this hook uses `beforeSwap` and `afterSwap`
- The address is crafted so its bits match these flags
- This is a v4 security feature - the address validates the hook's capabilities

---

```solidity
deployCodeTo("CounterHook.sol:CounterHook", abi.encode(manager), address(hook));
```

This deploys your `CounterHook` contract **to the specific address calculated above**.

- `"CounterHook.sol:CounterHook"` - The contract to deploy
- `abi.encode(manager)` - Constructor arguments (the PoolManager)
- `address(hook)` - Deploy to this exact address (the one with correct flag bits)

This is a Foundry testing feature (`deployCodeTo`) that lets you deploy to a specific address.

---

```solidity
deployMintAndApprove2Currencies();
```

Another `Deployers` utility that:
- Deploys two test ERC20 tokens (`currency0` and `currency1`)
- Mints tokens to the test contract
- Approves the routers to spend these tokens

---

```solidity
vm.label(Currency.unwrap(currency0), "currency0");
vm.label(Currency.unwrap(currency1), "currency1");
```

Labels the token addresses for easier debugging in Foundry traces.
- `Currency.unwrap()` - Converts from Uniswap's `Currency` type to a raw address

---

## `test_swap_counter()` Function

```solidity
(key,) = initPoolAndAddLiquidity(
  currency0, 
  currency1, 
  IHooks(address(hook)), 
  LPFeeLibrary.DYNAMIC_FEE_FLAG, 
  SQRT_PRICE_1_1
);
```

This **creates and initializes a new liquidity pool**:

- `currency0, currency1` - The two tokens in the pool
- `IHooks(address(hook))` - Attaches your CounterHook to this pool
- `LPFeeLibrary.DYNAMIC_FEE_FLAG` - Enables dynamic fees (required when using hooks)
- `SQRT_PRICE_1_1` - Initial price (1:1 ratio between tokens)
- Returns `key` - A `PoolKey` struct that uniquely identifies this pool

The function also adds initial liquidity to the pool so swaps can happen.

---

```solidity
PoolSwapTest.TestSettings memory testSettings = 
  PoolSwapTest.TestSettings({
    takeClaims: false, 
    settleUsingBurn: false
  });
```

Configures how the swap should be executed:
- `takeClaims: false` - Don't use the claims system (advanced v4 feature)
- `settleUsingBurn: false` - Settle balances normally, don't burn tokens

---

```solidity
console.log("Swap Number:", hook.swapNumber());
```

Logs the current swap counter (should be 1, since you initialized it to 1).

---

```solidity
for (uint256 i = 0; i < 9; i++) {
  swapRouter.swap(key, SWAP_PARAMS, testSettings, ZERO_BYTES);
  console.log("Swap Number:", hook.swapNumber());
}
```

**Executes 9 swaps**:
- `swapRouter.swap()` - Calls the swap router
- `key` - Identifies which pool to swap in
- `SWAP_PARAMS` - Swap parameters (amount, direction, etc.) from `Deployers`
- `testSettings` - The settings we defined above
- `ZERO_BYTES` - No additional hook data

After each swap:
1. `beforeSwap` is called (checks if counter < 10)
2. The swap executes
3. `afterSwap` is called (increments counter)

---

```solidity
assertEq(10, hook.swapNumber());
```

Verifies that after 9 swaps (starting from 1), the counter is now 10.

---

```solidity
vm.expectRevert();
swapRouter.swap(key, SWAP_PARAMS, testSettings, ZERO_BYTES);
```

Tests that the 10th swap **reverts** (because counter is already 10).
- `vm.expectRevert()` - Tells Foundry "the next call should revert"
- If the swap doesn't revert, the test fails

---

```solidity
vm.prank(address(manager));
vm.expectRevert(CounterHook.MaxNumberReached.selector);
hook.beforeSwap(address(this), key, SWAP_PARAMS, ZERO_BYTES);
```

Directly tests the `beforeSwap` function:
- `vm.prank(address(manager))` - Pretends the next call comes from the PoolManager (required due to `onlyPoolManager` modifier)
- `vm.expectRevert(CounterHook.MaxNumberReached.selector)` - Expects the specific custom error
- Calls `beforeSwap` directly and confirms it reverts with the right error

---

```solidity
console.log("Swap Number:", hook.swapNumber());
assertEq(10, hook.swapNumber());
```

Final verification that the counter stayed at 10.

---

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test -vv
```

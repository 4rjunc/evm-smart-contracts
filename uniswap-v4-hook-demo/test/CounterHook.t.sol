// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test} from "../lib/forge-std/src/Test.sol";

import {console} from "../lib/forge-std/src/console.sol";
import {CounterHook} from "../src/CounterHook.sol";

import {Hooks} from "@uniswap/lib/v4-core/src/libraries/Hooks.sol";
import {Currency} from "@uniswap/lib/v4-core/src/types/Currency.sol";
import {Deployers} from "@uniswap/lib/v4-core/test/utils/Deployers.sol";
import {IHooks} from "@uniswap/lib/v4-core/src/interfaces/IHooks.sol";
import {LPFeeLibrary} from "@uniswap/lib/v4-core/src/libraries/LPFeeLibrary.sol";
import {PoolSwapTest} from "@uniswap/lib/v4-core/src/test/PoolSwapTest.sol";


contract CounterHookTest is Test, Deployers{
  CounterHook hook;
  
  function setUp() public {
    deployFreshManagerAndRouters();

    hook = CounterHook(
      address(
        uint160(Hooks.AFTER_SWAP_FLAG | Hooks.BEFORE_SWAP_FLAG)
      )
    );

    deployCodeTo("CounterHook.sol:CounterHook", abi.encode(manager), address(hook));

    deployMintAndApprove2Currencies();

    vm.label(Currency.unwrap(currency0), "currency0");
    vm.label(Currency.unwrap(currency1), "currency1");
  }

  function test_swap_counter() public{
    (key,) = initPoolAndAddLiquidity(currency0, currency1, IHooks(address(hook)), LPFeeLibrary.DYNAMIC_FEE_FLAG, SQRT_PRICE_1_1);

    PoolSwapTest.TestSettings memory testSettings = 
      PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false});

    console.log("Swap Number:", hook.swapNumber());

    for (uint256 i = 0; i < 9; i++) {
      swapRouter.swap(key, SWAP_PARAMS, testSettings, ZERO_BYTES);
      console.log("Swap Number:", hook.swapNumber());
    }

    assertEq(10, hook.swapNumber());

    vm.expectRevert();
    swapRouter.swap(key, SWAP_PARAMS, testSettings, ZERO_BYTES);

    vm.prank(address(manager));
    vm.expectRevert(CounterHook.MaxNumberReached.selector);
    hook.beforeSwap(address(this), key, SWAP_PARAMS, ZERO_BYTES);

    console.log("Swap Number:", hook.swapNumber());
    assertEq(10, hook.swapNumber());
  }
}

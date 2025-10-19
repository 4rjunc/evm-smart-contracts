// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@uniswap/src/base/BaseHook.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/lib/v4-core/src/types/BeforeSwapDelta.sol";

contract CounterHook is BaseHook{

    uint256 swapNumber = 0;
    error MaxNumberReached();

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }
}

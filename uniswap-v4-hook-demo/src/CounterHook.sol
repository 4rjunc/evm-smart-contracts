// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@uniswap/src/base/BaseHook.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/lib/v4-core/src/types/BeforeSwapDelta.sol";
import {IPoolManager, SwapParams, ModifyLiquidityParams} from "@uniswap/lib/v4-core/src/interfaces/IPoolManager.sol";

contract CounterHook is BaseHook {
    uint24 public swapNumber = 1;
    error MaxNumberReached();

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: false,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: false,
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

    function beforeSwap(
        address,
        PoolKey calldata,
        SwapParams calldata,
        bytes calldata
    )
        external
        override
        onlyPoolManager
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        if (swapNumber >= 10) revert MaxNumberReached();
        return (
            BaseHook.beforeSwap.selector,
            BeforeSwapDeltaLibrary.ZERO_DELTA,
            0
        );
    }

    function afterSwap(
        address,
        PoolKey calldata,
        SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) external override onlyPoolManager returns (bytes4, int128) {
        swapNumber++;
        return (BaseHook.afterSwap.selector, 0);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import { DogToken } from "src/DogToken.sol";

import { PoolKey} from "v4-core/types/PoolKey.sol";
import { Currency } from "v4-core/types/Currency.sol";
import { IHooks } from "v4-core/interfaces/IHooks.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

contract CreatePool is Script {

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
    
        DogToken token1 = new DogToken("Dog Coin", "DOG", 18, 1_000_000 ether); // One million tokens minted

        /*
          Pool: ETH - DOG
          Fee: 500 = 0.05%
          TickSpacing: 10 // responsible for price management
          Hooks: no hook contract
        */
        PoolKey memory pool = PoolKey({
          currency0: Currency.wrap(address(0)),
          currency1: Currency.wrap(address(token1)),
          fee: 500,
          tickSpacing: 10,
          hooks: IHooks(address(0))
        });

        // floor(sqrt(token1/token0) * 2^96)

        // 1 ETH = 1000 DOGS
        uint256 amount0 = 1;
        uint256 amount1 = 1000;

        uint160 startingPrice = encodeSqrtRatioX96(amount1, amount0);
        int24 poolTick = IPoolManager(0xE03A1074c86CFeDd5C142C4F04F1a1536e203543).initialize(pool, startingPrice);

        console.log("Token deployed at: ", address(token1));
        console.log("Pool tick is: ", poolTick);

        vm.stopBroadcast();
    }

    function encodeSqrtRatioX96(uint256 amount1, uint256 amount0) internal pure returns (uint160 sqrtPriceX96) {
        require(amount0 > 0, "PriceMath: division by zero");
        // Multiply amount1 by 2^192 (left shift by 192) to preserve precision after the square root.
        uint256 ratioX192 = (amount1 << 192) / amount0;
        uint256 sqrtRatio = Math.sqrt(ratioX192);
        require(sqrtRatio <= type(uint160).max, "PriceMath: sqrt overflow");
        sqrtPriceX96 = uint160(sqrtRatio);
    }
}

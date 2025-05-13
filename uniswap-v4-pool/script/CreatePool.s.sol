// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import { DogToken } from "src/DogToken.sol";

import { PoolKey} from "v4-core/types/PoolKey.sol";
import { Currency } from "v4-core/types/Currency.sol";
import { IHooks } from "v4-core/interfaces/IHooks.sol";
//import { Math } from "@openzepplin/contract/utils/math/Math.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

contract CounterScript is Script {

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


        vm.stopBroadcast();
    }
}

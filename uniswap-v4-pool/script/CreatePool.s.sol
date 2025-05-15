// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MockToken} from "src/MockToken.sol";

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolModifyLiquidityTest} from "v4-core/test/PoolModifyLiquidityTest.sol";

contract CreatePool is Script {
    function setUp() public {}

    function run() public {
        // Start sending all the following contract calls or transactions as actual on-chain transactions, using a private key.
        vm.startBroadcast();

        // MockToken token0 = new MockToken("Dog Coin", "DOG", 18, 1_000_000_000 ether); // One billion tokens minted
        MockToken token1 = new MockToken("Cat Coin", "CAT", 18, 1_000_000_000 ether); // One billion tokens minted

        // console.log("DOG: ");
        // console.logAddress(address(token0));
        console.log("CAT: ");
        console.logAddress(address(token1));
        //
        // Creating a pool
        // address DOG = address(0x9470Bda003d4bd767E0ce73bE1C32c30cE37b34F); // DOG
        address CAT = address(token); // CAT
        address hook = address(0);
        uint24 swapFee = 4000; // 0.40%
        int24 tickSpacing = 10;

        uint256 token0Amount = 1e15;
        uint256 token1Amount = 100e18;

        PoolKey memory pool = PoolKey({
          currency0: Currency.wrap(address(0)),
          currency1: Currency.wrap(CAT),
          fee: swapFee,
          tickSpacing: tickSpacing,
          hooks: IHooks(hook)
        });

        uint160 startingPrice = encodeSqrtRatioX96(token0Amount, token1Amount);
        int24 poolTick = IPoolManager(0xE03A1074c86CFeDd5C142C4F04F1a1536e203543).initialize(pool, startingPrice);
        
        // Adding liquidity
        PoolModifyLiquidityTest lpRouter = PoolModifyLiquidityTest(0x0C478023803a644c94c4CE1C1e7b9A087e411B0A);
        
        uint256 amount0Max = token0Amount + 1 wei;
        uint256 amount1Max = token1Amount + 1 wei;
        
        // // approve tokens to the LP Router
        // IERC20(token0).approve(address(lpRouter), type(uint256).max);
        //
        // IERC20(token1).approve(address(lpRouter), type(uint256).max);
        //
        // int24 tickLower = -600;
        // int24 tickUpper = 600;
        // int256 liquidity = 10_000e18;
        //
        // lpRouter.modifyLiquidity(
        //     pool,
        //     IPoolManager.ModifyLiquidityParams({tickLower: tickLower, tickUpper: tickUpper, liquidityDelta: liquidity, salt: 0}),
        //     new bytes(0)
        // );
        //
        /*
          Pool: ETH - DOG
          Fee: 500 = 0.05%
          TickSpacing: 10 // responsible for price management
          Hooks: no hook contract
        */
        // PoolKey memory pool = PoolKey({
        //   currency0: Currency.wrap(address(0)),
        //   currency1: Currency.wrap(address(token1)),
        //   fee: 500,
        //   tickSpacing: 10,
        //   hooks: IHooks(address(0))
        // });
        //
        // floor(sqrt(token1/token0) * 2^96)

        // 1 ETH = 1000 DOGS
        // uint256 amount0 = 1;
        // uint256 amount1 = 1000;
        //
        // uint160 startingPrice = encodeSqrtRatioX96(amount1, amount0);
        // int24 poolTick = IPoolManager(0xE03A1074c86CFeDd5C142C4F04F1a1536e203543).initialize(pool, startingPrice);
        //
        // console.log("Token deployed at: ", address(token1));
        // console.log("Pool tick is: ", poolTick);

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

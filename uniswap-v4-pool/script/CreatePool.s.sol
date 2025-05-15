// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MockToken} from "src/MockToken.sol";

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolModifyLiquidityTest} from "v4-core/src/test/PoolModifyLiquidityTest.sol";

import {IPoolInitializer_v4} from "v4-periphery/src/interfaces/IPoolInitializer_v4.sol";
import {Actions} from "v4-periphery/src/libraries/Actions.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
//import {PositionManager} from "v4-periphery/PositionManager.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";


import {IAllowanceTransfer} from "v4-periphery/lib/permit2/src/interfaces/IAllowanceTransfer.sol";
import {LiquidityAmounts} from "v4-core/test/utils/LiquidityAmounts.sol";

contract CreatePool is Script {
    function setUp() public {}

    function run() public {
        // Start sending all the following contract calls or transactions as actual on-chain transactions, using a private key.
        vm.startBroadcast();

        ////////////////////////////////////////////// CREATE POOL //////////////////////////////////////////////
        // MockToken token0 = new MockToken("Dog Coin", "DOG", 18, 1_000_000_000 ether); // One billion tokens minted
        //MockToken token1 = new MockToken("Cat Coin", "CAT", 18, 1_000_000_000 ether); // One billion tokens minted

        // console.log("DOG: ");
        // console.logAddress(address(token0));
        //console.log("CAT: ");
        //console.logAddress(address(token1));

        // address DOG = address(0x9470Bda003d4bd767E0ce73bE1C32c30cE37b34F); // DOG
        //address CAT = address(token1); // CAT
        address hook = address(0);
        uint24 swapFee = 4000; // 0.40%
        int24 tickSpacing = 10; // tickSpacing is the granularity of the pool. Lower values are more precise but may be more expensive to trade on

        uint256 token0Amount = 1e15;
        uint256 token1Amount = 2_000_000e18;

        // PoolKey memory pool = PoolKey({
        //   currency0: Currency.wrap(address(0)), // ETH
        //   currency1: Currency.wrap(CAT), // CAT Token
        //   fee: swapFee,
        //   tickSpacing: tickSpacing,
        //   hooks: IHooks(hook)
        // });
        //
        uint160 startingPrice = encodeSqrtRatioX96(token0Amount, token1Amount);
        // int24 poolTick = IPoolManager(0xE03A1074c86CFeDd5C142C4F04F1a1536e203543).initialize(pool, startingPrice);

        // ------------------------------------------- NOTES ------------------------------------------- 
        // Two transactions will happen once in minting 1 Billion tokens bhttps://sepolia.etherscan.io/tx/0x3ae6774e61dd21ac7cdfed82ff03b40dd71483fba9b81d16d49b79bb5cea6275
        // second one initialize a Uniswap v4 Pool without initial liquidity https://sepolia.etherscan.io/tx/0xacd06670cbdeed8af7364d91c457bbb9cc735e9e9327e6c8f1b6c20a3446382c

        // PURFECT OK!

        ////////////////////////////////////////////// ONLY CREATE POOL END //////////////////////////////////////////////


        ////////////////////////////////////////////// CREATE A POOL & ADD LIQUIDITY //////////////////////////////////////////////
        // Uniswap v4's PositionManager supports atomic creation of a pool and initial liquidity using multicall. Developers can create a trading pool, with liquidity, in a single transaction:
        // The PositionManager (PosM) contract is responsible for creating liquidity positions on v4. PosM mints and manages ERC721 tokens associated with each position.
        // READ MORE: https://docs.uniswap.org/contracts/v4/reference/periphery/PositionManager

        MockToken token2 = new MockToken("DOGE COIN", "DOGE", 18, 1_000_000_000 ether); // One billion tokens minted
        console.log("DOGE: ");
        console.logAddress(address(token2));
        uint256 amount0Max = token0Amount + 1 wei;
        uint256 amount1Max = token1Amount + 1 wei;
        bytes memory hookData = new bytes(0);
        IPositionManager posm = IPositionManager(0x429ba70129df741B2Ca2a85BC3A2a3328e5c09b4);
        IAllowanceTransfer PERMIT2 = IAllowanceTransfer(address(0x000000000022D473030F116dDEE9F6B43aC78BA3));

        // range of position
        int24 tickLower = -600; // must be a multiple of tickSpacing
        int24 tickUpper = 600;

        // 1. Initialize the parameters provided to multicall()
        bytes[] memory params = new bytes[](2);
        
        // 2. Configure the pool 
        PoolKey memory pool2 = PoolKey({
                currency0: CurrencyLibrary.ADDRESS_ZERO ,
                currency1: Currency.wrap(address(token2)),
                fee: swapFee,
                tickSpacing: tickSpacing,
                hooks: IHooks(hook)
        });

        // 3. Encode the initializePool parameters
        params[0] = abi.encodeWithSelector(
            IPoolInitializer_v4.initializePool.selector,
            pool2,
            startingPrice
        );
        
        // 4. Initialize the mint-liquidity parameters
        bytes memory actions = abi.encodePacked(uint8(Actions.MINT_POSITION), uint8(Actions.SETTLE_PAIR));
        // The first command MINT_POSITION creates a new liquidity position
        // The second command SETTLE_PAIR indicates that tokens are to be paid by the caller, to create the position

        // 5. Encode the MINT_POSITION parameters

        // Converts token amounts to liquidity units
        // Computes the maximum amount of liquidity received for a given amount of token0, token1, the current pool prices and the prices at the tick boundaries
        // READ MORE: https://docs.uniswap.org/contracts/v3/reference/periphery/libraries/LiquidityAmounts#getliquidityforamounts
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            startingPrice,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            token0Amount,
            token1Amount
        );

        bytes[] memory mintParams = new bytes[](2);
        mintParams[0] = abi.encode(pool2, tickLower, tickUpper, liquidity, amount0Max, amount1Max, msg.sender, hookData); // try: address(this) -> msg.sender
        // pool the same PoolKey defined above, in pool-creation
        // tickLower and tickUpper are the range of the position, must be a multiple of pool.tickSpacing
        // liquidity is the amount of liquidity units to add, see LiquidityAmounts for converting token amounts to liquidity units
        // amount0Max and amount1Max are the maximum amounts of token0 and token1 the caller is willing to transfer   
        // recipient is the address that will receive the liquidity position (ERC-721) 
        // hookData is the optional hook data

        // 6. Encode the SETTLE_PAIR parameters
        mintParams[1] = abi.encode(pool2.currency0, pool2.currency1);

        // 7. Encode the modifyLiquidites call
        uint256 deadline = block.timestamp + 60;
        params[1] = abi.encodeWithSelector(
            posm.modifyLiquidities.selector, abi.encode(actions, mintParams), deadline
        );

        // 8. Approve the tokens2
        token2.approve(address(PERMIT2), type(uint256).max);
        PERMIT2.approve(address(token2), address(posm), type(uint160).max, type(uint48).max);

        IPositionManager(posm).multicall{value: amount0Max}(params);
        console.log("WORKED TILL YOU WROTE");


        ////////////////////////////////////////////// CREATE A POOL & ADD LIQUIDITY END //////////////////////////////////////////////
        
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Uniswap V4 imports
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {CurrencyLibrary} from "v4-core/src/types/Currency.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";
import {IPoolInitializer_v4} from "v4-periphery/src/interfaces/IPoolInitializer_v4.sol";
import {Actions} from "v4-periphery/src/libraries/Actions.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {LiquidityAmounts} from "v4-core/test/utils/LiquidityAmounts.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {LiquidityAmounts} from "v4-core/test/utils/LiquidityAmounts.sol";

contract TokenContract is ERC20, Ownable {
    using CurrencyLibrary for Currency;

    // ============ Constants ============
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10 ** 18; // 1 Billion tokens
    uint256 public constant REQUIRED_ETH = 3.5 ether;
    uint256 public constant POOL_TOKENS = 200_000_000 * 10 ** 18; // 200M tokens for pool

    // ============ Uniswap V4 Addresses ============
    // These addresses need to be set for your network (Sepolia, mainnet, etc.)
    address public immutable poolManager; // Uniswap V4 Pool Manager
    address public immutable positionManager; // Position Manager for liquidity
    address public immutable permit2; // Permit2 for token approvals

    // ============ State Variables ============
    bool public ethReceived;
    bool public poolCreated;
    uint256 public positionTokenId; // ERC-721 token ID representing liquidity position

    // ============ Events ============
    event ETHReceived(address indexed from, uint256 amount);
    event ETHWithdrawn(address indexed to, uint256 amount);
    event PoolCreated(address indexed pool, uint256 tokenId);

    /**
     * @dev Constructor
     * @param _poolManager Address of Uniswap V4 PoolManager
     * @param _positionManager Address of Uniswap V4 PositionManager
     * @param _permit2 Address of Permit2 contract
     */
    constructor(address _poolManager, address _positionManager, address _permit2)
        ERC20("MyToken", "MTK")
        Ownable(msg.sender)
    {
        require(_poolManager != address(0), "Invalid pool manager");
        require(_positionManager != address(0), "Invalid position manager");
        require(_permit2 != address(0), "Invalid permit2");

        poolManager = _poolManager;
        positionManager = _positionManager;
        permit2 = _permit2;

        // Mint 1 billion tokens to the contract itself (not deployer)
        // We need tokens in the contract to create the pool
        _mint(address(this), TOTAL_SUPPLY);
    }

    /**
     * @dev Function to receive exactly 3.5 ETH
     * Can only be called once
     */
    function receiveETH() external payable {
        require(!ethReceived, "ETH already received");
        require(msg.value >= REQUIRED_ETH, "Send 3.5 ETH or more");

        ethReceived = true;
        emit ETHReceived(msg.sender, msg.value);
    }

    /**
     * @dev Creates Uniswap V4 pool with 3.5 ETH and 200M tokens
     * Can only be called by owner and only once
     * Requires ETH to be received first
     */
    function createUniswapPool() external onlyOwner {
        require(ethReceived, "Must receive ETH first");
        require(!poolCreated, "Pool already created");
        require(address(this).balance >= REQUIRED_ETH, "Insufficient ETH");

        poolCreated = true;

        Currency ethCurrency = Currency.wrap(address(0));
        Currency tokenCurrency = Currency.wrap(address(this));

        // ETH is always currency0 (lower address)
        Currency currency0 = ethCurrency;
        Currency currency1 = tokenCurrency;

        int24 tickSpacing = 60;
        uint160 startingPrice = 10480900742267666059490990;

        uint256 token0Amount = 3.5 ether;
        uint256 token1Amount = 200_000_000e18;

        // range of the position, must be a multiple of tickSpacing
        int24 tickLower;
        int24 tickUpper;

        PoolKey memory poolKey =
            PoolKey({currency0: currency0, currency1: currency1, fee: 3000, tickSpacing: 60, hooks: IHooks(address(0))});

        //uint160 sqrtPriceX96 = 598593874676037306090487096320;

        // Approve tokens
        _approve(address(this), permit2, POOL_TOKENS);

        IAllowanceTransfer(permit2).approve(
            address(this), positionManager, uint160(POOL_TOKENS), uint48(block.timestamp + 3600)
        );

        bytes[] memory params = new bytes[](2);

        params[0] = abi.encodeWithSelector(IPoolInitializer_v4.initializePool.selector, poolKey, startingPrice);

        bytes memory actions = abi.encodePacked(uint8(Actions.MINT_POSITION), uint8(Actions.SETTLE_PAIR));

        int24 currentTick = TickMath.getTickAtSqrtPrice(startingPrice);

        tickLower = truncateTickSpacing((currentTick - 750 * tickSpacing), tickSpacing);
        tickUpper = truncateTickSpacing((currentTick + 750 * tickSpacing), tickSpacing);

        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            startingPrice,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            token0Amount,
            token1Amount
        );

        bytes[] memory mintParams = new bytes[](2);

        mintParams[0] =
            abi.encode(poolKey, tickLower, tickUpper, liquidity, POOL_TOKENS, REQUIRED_ETH, address(this), "");

        mintParams[1] = abi.encode(poolKey.currency0, poolKey.currency1);

        uint256 deadline = block.timestamp + 3600;

        params[1] = abi.encodeWithSelector(
            IPositionManager.modifyLiquidities.selector, abi.encode(actions, mintParams), deadline
        );

        bytes[] memory results = IPositionManager(positionManager).multicall{value: REQUIRED_ETH}(params);

        // positionTokenId = abi.decode(results[1], (uint256));
        //
        // emit PoolCreated(address(poolManager), positionTokenId);
    }

    function truncateTickSpacing(int24 tick, int24 tickSpacing) internal pure returns (int24) {
        /// forge-lint: disable-next-line(divide-before-multiply)
        return ((tick / tickSpacing) * tickSpacing);
    }

    /**
     * @dev Owner-only function to withdraw ETH from contract
     * @param amount Amount of ETH to withdraw (in wei)
     */
    function withdrawETH(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");

        (bool success,) = payable(owner()).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit ETHWithdrawn(owner(), amount);
    }

    /**
     * @dev Withdraw all ETH from contract
     */
    function withdrawAllETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");

        (bool success,) = payable(owner()).call{value: balance}("");
        require(success, "ETH transfer failed");

        emit ETHWithdrawn(owner(), balance);
    }

    /**
     * @dev Get contract's ETH balance
     */
    function getETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Fallback function to reject direct ETH transfers
     */
    receive() external payable {
        revert("Use receiveETH() function");
    }
}

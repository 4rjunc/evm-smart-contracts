// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/TokenContractV4.sol";

contract InteractTokenV4 is Script {
    // Helper function to get token address
    function getTokenAddress() internal view returns (address payable) {
        try vm.readFile(
            string.concat(
                vm.projectRoot(),
                "/broadcast/DeployTokenV4.s.sol/",
                vm.toString(block.chainid),
                "/latest_deployment.txt"
            )
        ) returns (string memory content) {
            address addr = vm.parseAddress(content);
            console.log("Using token address from deployment file:", addr);
            return payable(addr);
        } catch {
            address addr = vm.envAddress("TOKEN_ADDRESS");
            console.log("Using token address from .env:", addr);
            return payable(addr);
        }
    }

    /**
     * @dev Send 3.5 ETH to the contract
     * Usage: forge script script/InteractTokenV4.s.sol:InteractTokenV4 --sig "sendETH()" --broadcast
     */
    function sendETH() external {
        //uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address payable tokenAddress = getTokenAddress();

        TokenContract token = TokenContract(tokenAddress);

        vm.startBroadcast();

        console.log("=== Sending 3.5 ETH to Contract ===");
        console.log("Current balance:", token.getETHBalance() / 1 ether, "ETH");
        console.log("");

        // Send 3.5 ETH
        token.receiveETH{value: 3.6 ether}();

        console.log(" Success! 3.5 ETH sent");
        console.log("New balance:", token.getETHBalance() / 1 ether, "ETH");
        console.log("");
        console.log(" Next step: Create Uniswap pool");
        console.log("   forge script script/InteractTokenV4.s.sol:InteractTokenV4 --sig 'createPool()' --broadcast");

        vm.stopBroadcast();
    }

    /**
     * @dev Create Uniswap V4 pool with 3.5 ETH and 200M tokens
     * Usage: forge script script/InteractTokenV4.s.sol:InteractTokenV4 --sig "createPool()" --broadcast
     */
    function createPool() external {
        //uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address payable tokenAddress = getTokenAddress();

        TokenContract token = TokenContract(tokenAddress);

        console.log("=== Creating Uniswap V4 Pool ===");
        console.log("Token:", address(token));
        console.log("ETH Balance:", token.getETHBalance() / 1 ether, "ETH");
        console.log("Token Balance:", token.balanceOf(address(token)) / 10 ** 18, "tokens");
        console.log("");

        // Check requirements
        require(token.ethReceived(), "Must send ETH first!");
        require(!token.poolCreated(), "Pool already created!");
        require(token.getETHBalance() >= 3.5 ether, "Need 3.5 ETH!");

        console.log(" Requirements met");
        console.log("Creating pool with:");
        console.log("  - 3.5 ETH");
        console.log("  - 200,000,000 tokens");
        console.log("  - 0.30% fee");
        console.log("  - Full range liquidity");
        console.log("");
        console.log(" This may take a moment...");

        vm.startBroadcast();

        // Create the pool
        token.createUniswapPool();

        vm.stopBroadcast();

        console.log("");
        console.log(" SUCCESS! Pool created!");
        console.log("   Position NFT ID:", token.positionTokenId());
        console.log("   Remaining ETH:", token.getETHBalance() / 1 ether, "ETH");
        console.log("   Remaining tokens:", token.balanceOf(address(token)) / 10 ** 18, "tokens");
        console.log("");
        console.log(" Your Uniswap V4 pool is now LIVE!");
        console.log("   People can now trade your token!");
    }

    /**
     * @dev Check contract status
     * Usage: forge script script/InteractTokenV4.s.sol:InteractTokenV4 --sig "checkStatus()" --rpc-url $SEPOLIA_RPC_URL
     */
    function checkStatus() external view {
        address payable tokenAddress = payable(vm.envAddress("TOKEN_ADDRESS"));

        TokenContract token = TokenContract(tokenAddress);

        console.log("         TOKEN CONTRACT STATUS (V4)                     ");
        console.log("");

        console.log(" Contract:", address(token));
        console.log(" Owner:", token.owner());
        console.log("");

        console.log(" Token Info:");
        console.log("   Name:", token.name());
        console.log("   Symbol:", token.symbol());
        console.log("   Total Supply:", token.totalSupply() / 10 ** 18, "tokens");
        console.log("");

        console.log(" Balances:");
        console.log("   Contract ETH:", token.getETHBalance() / 1 ether, "ETH");
        console.log("   Contract Tokens:", token.balanceOf(address(token)) / 10 ** 18, "tokens");
        console.log("");

        console.log(" Uniswap Status:");
        console.log("   ETH Received:", token.ethReceived() ? " Yes" : " No");
        console.log("   Pool Created:", token.poolCreated() ? " Yes" : " No");

        if (token.poolCreated()) {
            console.log("   Position NFT ID:", token.positionTokenId());
        }
        console.log("");

        console.log(" Next Steps:");
        if (!token.ethReceived()) {
            console.log("   1.  Send 3.5 ETH");
            console.log("      forge script script/InteractTokenV4.s.sol:InteractTokenV4 --sig 'sendETH()' --broadcast");
        } else if (!token.poolCreated()) {
            console.log("   1.  ETH received");
            console.log("   2.  Create Uniswap pool");
            console.log(
                "      forge script script/InteractTokenV4.s.sol:InteractTokenV4 --sig 'createPool()' --broadcast"
            );
        } else {
            console.log("   ALL DONE! Pool is live on Uniswap V4! ");
        }
        console.log("");
    }

    /**
     * @dev Withdraw ETH (only if pool not created)
     * Usage: forge script script/InteractTokenV4.s.sol:InteractTokenV4 --sig "withdraw()" --broadcast
     */
    function withdraw() external {
        //uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address payable tokenAddress = getTokenAddress();

        TokenContract token = TokenContract(tokenAddress);

        vm.startBroadcast();

        console.log("=== Withdrawing ETH ===");
        console.log("Balance before:", token.getETHBalance() / 1 ether, "ETH");

        token.withdrawAllETH();

        console.log("Balance after:", token.getETHBalance() / 1 ether, "ETH");
        console.log(" Withdrawn to owner");

        vm.stopBroadcast();
    }
}

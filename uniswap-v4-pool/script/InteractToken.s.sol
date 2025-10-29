// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/TokenContract.sol";

contract InteractToken is Script {
    function run() external {
        //uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address payable tokenAddress = payable(vm.envAddress("TOKEN_ADDRESS"));

        TokenContract token = TokenContract(tokenAddress);

        vm.startBroadcast();

        // Check initial state
        console.log("=== Initial State ===");
        console.log("Contract ETH Balance:", token.getETHBalance());
        console.log("ETH Received:", token.ethReceived());

        // Send 3.5 ETH to the contract
        console.log("\n=== Sending 3.5 ETH ===");
        token.receiveETH{value: 3.5 ether}();
        console.log("ETH sent successfully!");
        console.log("Contract ETH Balance:", token.getETHBalance());
        console.log("ETH Received:", token.ethReceived());

        vm.stopBroadcast();
    }

    function withdraw() external {
        //uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address payable tokenAddress = payable(vm.envAddress("TOKEN_ADDRESS"));

        TokenContract token = TokenContract(tokenAddress);

        vm.startBroadcast();

        console.log("=== Before Withdrawal ===");
        console.log("Contract ETH Balance:", token.getETHBalance());

        // Withdraw all ETH
        token.withdrawAllETH();

        console.log("\n=== After Withdrawal ===");
        console.log("Contract ETH Balance:", token.getETHBalance());

        vm.stopBroadcast();
    }
}

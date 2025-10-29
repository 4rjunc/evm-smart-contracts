// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/TokenContract.sol";

contract DeployToken is Script {
    function run() external returns (TokenContract) {
        // Start broadcasting transactions
        //uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast();

        // Deploy the contract
        TokenContract token = new TokenContract();

        console.log("TokenContract deployed at:", address(token));
        console.log("Total Supply:", token.totalSupply() / 10 ** 18, "tokens");
        console.log("Owner:", token.owner());

        vm.stopBroadcast();

        return token;
    }
}

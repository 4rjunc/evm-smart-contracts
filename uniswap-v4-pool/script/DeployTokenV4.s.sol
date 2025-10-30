// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/TokenContractV4.sol";

contract DeployTokenV4 is Script {
    // Uniswap V4 addresses - UPDATE THESE FOR YOUR NETWORK
    //
    // For Sepolia testnet, you need to find:
    // - PoolManager address
    // - PositionManager address
    // - Permit2 address
    //
    // Check: https://docs.uniswap.org/contracts/v4/deployments

    // BASE SEPOLIA
    // address constant POOL_MANAGER = 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408;
    // address constant POSITION_MANAGER = 0x4B2C77d209D3405F41a037Ec6c77F7F5b8e2ca80;
    // address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    // UNICHAIN SEPOLIA
    address constant POOL_MANAGER = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;
    address constant POSITION_MANAGER = 0xf969Aee60879C54bAAed9F3eD26147Db216Fd664;
    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    function run() external returns (address) {
        // Validation check
        require(POOL_MANAGER != address(0), "UPDATE POOL_MANAGER ADDRESS!");
        require(POSITION_MANAGER != address(0), "UPDATE POSITION_MANAGER ADDRESS!");

        //uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast();

        console.log("Deploying TokenContract with Uniswap V4 integration...");
        console.log("");
        console.log("Using addresses:");
        console.log("  PoolManager:", POOL_MANAGER);
        console.log("  PositionManager:", POSITION_MANAGER);
        console.log("  Permit2:", PERMIT2);
        console.log("");

        // Deploy the contract
        TokenContract token = new TokenContract(POOL_MANAGER, POSITION_MANAGER, PERMIT2);

        console.log(" TokenContract deployed at:", address(token));
        console.log("   Total Supply:", token.totalSupply() / 10 ** 18, "tokens");
        console.log("   Owner:", token.owner());
        console.log("");
        console.log(" Next steps:");
        console.log(
            "   1. Send 3.5 ETH: forge script script/InteractTokenV4.s.sol:InteractTokenV4 --sig 'sendETH()' --broadcast"
        );
        console.log(
            "   2. Create pool: forge script script/InteractTokenV4.s.sol:InteractTokenV4 --sig 'createPool()' --broadcast"
        );

        vm.stopBroadcast();

        // // Save address to file
        // string memory addressFile = string.concat(
        //     vm.projectRoot(), "/broadcast/DeployTokenV4.s.sol/", vm.toString(block.chainid), "/latest_deployment.txt"
        // );
        // vm.writeFile(addressFile, vm.toString(address(token)));

        return address(token);
    }
}

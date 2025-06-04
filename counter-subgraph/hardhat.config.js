require("@nomiclabs/hardhat-ethers");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL,
      accounts: [process.env.PRIVATE_KEY],
      gas: 2100000,
      gasPrice: 8000000000, // 8 gwei
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};;

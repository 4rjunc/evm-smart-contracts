const hre = require("hardhat");

// Contract Files
const Counter = 'Counter'

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const contract = await hre.ethers.getContractFactory(Counter);
  const contract_dep = await contract.deploy();

  // Wait for deployment to complete
  await contract_dep.deployed();

  console.log("Contract deployed to:", contract_dep.address);

  // Optional: Test the contract
  console.log("Initial counter value:", await contract_dep.counter());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

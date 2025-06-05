# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

## Setting Up Subgraph 

- Create an account in Subgraph
- Create a subgraph from dashboard
- Install Graph cli tool in your system
- Intialize a subgraph project in your contracts directory

```zsh
󰄛 ❯ graph init counter
✔ Network · Ethereum Sepolia Testnet · sepolia · https://sepolia.etherscan.io
✔ Source · Smart Contract · ethereum
✔ Subgraph slug · counter
✔ Directory to create the subgraph in · counter
✔ Contract address · 0xA1BE4e668B740D4E99d58654a92D66961b44b5Be
✔ Fetching ABI from Sourcify API...
✖ Failed to fetch ABI: Failed to fetch ABI: Error: NOTOK - Contract source code not verified
✔ Do you want to retry? (Y/n) · false
✔ Fetching start block from Contract API...
✖ Failed to fetch contract name: Name not found
✔ Do you want to retry? (Y/n) · false
✔ ABI file (path) · counter.json
✔ Start block · 8474094
✔ Contract name · Counter
✔ Index contract events as entities (Y/n) · true
  Generate subgraph
  Write subgraph to directory
✔ Create subgraph scaffold
✔ Initialize networks config
✔ Initialize subgraph repository
✔ Install dependencies with yarn
✔ Generate ABI and schema types with yarn codegen
✔ Add another contract? (y/N) · false

Subgraph counter created in counter

Next steps:

  1. Run `graph auth` to authenticate with your deploy key.

  2. Type `cd counter` to enter the subgraph.

  3. Run `yarn deploy` to deploy the subgraph.

Make sure to visit the documentation on https://thegraph.com/docs/ for further information.

```


```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.js
```

### to run testcases in sepolia
```
npx hardhat run scripts/interactSepolia.js --network sepolia
```

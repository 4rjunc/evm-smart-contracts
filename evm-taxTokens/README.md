# TaxToken Project

This project implements a custom ERC20 token with a built-in tax mechanism. Each transfer incurs a 10% tax that is sent to a burn address, effectively reducing the total supply over time.

## Contract Overview

`TaxToken` is an ERC20-compliant token with the following features:

- **Name**: TaxToken
- **Symbol**: TT
- **Decimals**: 18 (standard ERC20)
- **Tax Mechanism**: 10% of each transfer is automatically sent to a burn address
- **Supply Mechanism**: Tokens can be minted by any user calling the `mintToMe` function

### How the Tax Works

When a user transfers tokens:
1. The contract verifies the sender has sufficient balance
2. 10% of the transfer amount is calculated as tax
3. 90% of the tokens are sent to the recipient
4. 10% of the tokens are sent to the burn address (`0x000000000000000000000000000000000000dEaD`)
5. The total transfer amount is deducted from the sender's balance

This mechanism creates natural deflationary pressure on the token supply, potentially increasing its value over time if demand remains constant.

## Project Setup

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Git](https://git-scm.com/downloads)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/4rjunc/evm-taxToken.git
   cd evm-taxToken
   ```

2. Install dependencies:
   ```bash
   forge install
   ```

### Compile

Compile the smart contracts:
```bash
forge build
```

### Testing

Run the test suite:
```bash
forge test
```

Run tests with verbose output:
```bash
forge test -vv
```

Run a specific test:
```bash
forge test --match-test testTransferWithTax -vv
```

### Deploy

To deploy to a local Anvil instance:
1. Start Anvil:
   ```bash
   anvil
   ```

2. Deploy the contract:
   ```bash
   forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --private-key <private-key> --broadcast
   ```

For deployment to a testnet or mainnet, update the RPC URL and private key accordingly.

## Project Structure

```
.
├── src/
│   └── TaxToken.sol       # Main contract
├── test/
│   └── TaxToken.t.sol     # Tests for TaxToken
├── script/
│   └── Deploy.s.sol       # Deployment script
└── README.md              # This file
```

## Contract Functionality

### Functions

- `constructor()`: Initializes the token with name "TaxToken" and symbol "TT"
- `mintToMe(uint amount)`: Mints the specified amount of tokens to the caller
- `transfer(address to, uint256 amount)`: Overrides the ERC20 transfer function to implement the tax mechanism

## License

This project is licensed under the UNLICENSED license.

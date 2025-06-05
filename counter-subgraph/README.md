# Smart Contract Event Indexing with The Graph Protocol - Quick Demo Guide

## Overview

Learn how to index Ethereum smart contract events using The Graph Protocol and query them in a React application. This guide provides a complete walkthrough from contract deployment to frontend integration.

### What You'll Learn
- **The Graph Protocol**: A decentralized protocol for indexing and querying blockchain data
- **Subgraphs**: Open APIs that allow anyone to create or query indexed blockchain data
- **React Integration**: How to fetch indexed data in your frontend applications

## Step 1: Create the Smart Contract

We'll use a simple counter contract that emits events for demonstration:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract Counter {
    uint256 public counter = 0;

    // Events to be indexed
    event CounterIncrement(uint256 newValue, address indexed caller);
    event CounterDecrement(uint256 newValue, address indexed caller);
    event CounterReset(address indexed caller);
    
    function increment() public {
        counter++;
        emit CounterIncrement(counter, msg.sender);
    }

    function decrement() public {
        require(counter > 0, "Counter cannot go below zero");
        counter--;
        emit CounterDecrement(counter, msg.sender);
    }

    function reset() public {
        counter = 0;
        emit CounterReset(msg.sender);
    }

    function getCounter() public view returns (uint256) {
        return counter;
    }
}
```

### Deploy the Contract
1. Compile and test your contract using Hardhat
2. Deploy to Sepolia testnet
3. Interact with the contract to generate some events:

```bash
npx hardhat run scripts/interactSepolia.js --network sepolia
```

## Step 2: Set Up The Graph Subgraph

### Prerequisites
1. Create an account at [The Graph Studio](https://thegraph.com/studio/)
2. Create a new subgraph project
3. Install The Graph CLI:

```bash
npm install -g @graphprotocol/graph-cli@latest
# or
yarn global add @graphprotocol/graph-cli
```

### Initialize Your Subgraph

**Important**: Save your contract's ABI as `counter.json` before initialization (required if your contract isn't verified on Etherscan).

```bash
❯ graph init counter
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

Follow the prompts:
- **Network**: Ethereum Sepolia Testnet
- **Source**: Smart Contract
- **Contract Address**: Your deployed contract address
- **ABI File**: `counter.json` (if contract isn't verified)
- **Start Block**: Block number when your contract was deployed
- **Contract Name**: Counter
- **Index Events**: Yes

### Deploy Your Subgraph

After initialization, follow these steps:

```bash
# 1. Authenticate with your deploy key (found in Graph Studio dashboard)
graph auth --studio YOUR_DEPLOY_KEY

# 2. Navigate to subgraph directory
cd counter

# 3. Deploy the subgraph
yarn deploy
```

### Generated GraphQL Schema

The Graph automatically generates this schema based on your contract events:

```graphql
type CounterDecrement @entity(immutable: true) {
  id: Bytes!
  newValue: BigInt! # uint256
  caller: Bytes! # address
  blockNumber: BigInt!
  blockTimestamp: BigInt!
  transactionHash: Bytes!
}

type CounterIncrement @entity(immutable: true) {
  id: Bytes!
  newValue: BigInt! # uint256
  caller: Bytes! # address
  blockNumber: BigInt!
  blockTimestamp: BigInt!
  transactionHash: Bytes!
}

type CounterReset @entity(immutable: true) {
  id: Bytes!
  caller: Bytes! # address
  blockNumber: BigInt!
  blockTimestamp: BigInt!
  transactionHash: Bytes!
}
```

## Step 3: Integrate with React App

### Install Dependencies

```bash
npm install @apollo/client graphql
```

### Create the Query Component

```jsx
'use client'

import React, { useEffect, useState } from 'react';
import { ApolloClient, InMemoryCache, gql } from '@apollo/client';

// Apollo Client setup
const client = new ApolloClient({
  uri: 'https://api.studio.thegraph.com/query/YOUR_SUBGRAPH_ID/counter/version/latest',
  cache: new InMemoryCache(),
  headers: {
    Authorization: 'Bearer YOUR_API_KEY' // Get from Graph Studio API tab
  }
});

// GraphQL query
const COUNTER_QUERY = gql`
  query GetCounterData {
    counterDecrements(first: 5, orderBy: blockTimestamp, orderDirection: desc) {
      id
      newValue
      caller
      blockNumber
      blockTimestamp
    }
    counterIncrements(first: 5, orderBy: blockTimestamp, orderDirection: desc) {
      id
      newValue
      caller
      blockNumber
      blockTimestamp
    }
  }
`;

export default function CounterSubgraphComponent() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    async function fetchData() {
      try {
        setLoading(true);
        const result = await client.query({
          query: COUNTER_QUERY,
          fetchPolicy: 'cache-first'
        });
        setData(result.data);
      } catch (err) {
        setError(err.message);
        console.error('Error fetching data:', err);
      } finally {
        setLoading(false);
      }
    }

    fetchData();
  }, []);

  if (loading) return <div>Loading indexed events...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <div className="max-w-4xl mx-auto p-6">
      <h1 className="text-2xl font-bold mb-6">Counter Contract Events</h1>
      
      <div className="grid md:grid-cols-2 gap-6">
        {/* Increments */}
        <div className="bg-green-50 p-4 rounded-lg">
          <h2 className="text-lg font-semibold mb-3 text-green-700">Recent Increments</h2>
          {data?.counterIncrements?.map((event) => (
            <div key={event.id} className="bg-white p-3 rounded mb-2">
              <div><strong>New Value:</strong> {event.newValue}</div>
              <div><strong>Caller:</strong> {event.caller}</div>
              <div><strong>Block:</strong> {event.blockNumber}</div>
            </div>
          ))}
        </div>

        {/* Decrements */}
        <div className="bg-red-50 p-4 rounded-lg">
          <h2 className="text-lg font-semibold mb-3 text-red-700">Recent Decrements</h2>
          {data?.counterDecrements?.map((event) => (
            <div key={event.id} className="bg-white p-3 rounded mb-2">
              <div><strong>New Value:</strong> {event.newValue}</div>
              <div><strong>Caller:</strong> {event.caller}</div>
              <div><strong>Block:</strong> {event.blockNumber}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
```

### Usage in Next.js

```jsx
// pages/index.js or app/page.js
import CounterSubgraphComponent from './components/CounterSubgraphComponent';

export default function Home() {
  return (
    <div>
      <CounterSubgraphComponent />
    </div>
  );
}
```

## Key Benefits

✅ **Real-time Data**: Events are indexed automatically as they occur  
✅ **Fast Queries**: Pre-indexed data means lightning-fast GraphQL queries  
✅ **Decentralized**: No single point of failure  
✅ **Developer Friendly**: Familiar GraphQL syntax  
✅ **Cost Effective**: Query multiple events in a single request  

## Quick Tips

- **API Keys**: Generate your API key from the Graph Studio dashboard
- **Query Optimization**: Use `first`, `orderBy`, and `orderDirection` parameters for better performance
- **Error Handling**: Always implement proper error handling for network requests
- **Caching**: Apollo Client provides built-in caching for better UX

## Complete Example

The full working React application with all components is available at: [subgraph-frontend repository](https://github.com/4rjunc/evm-smart-contracts/tree/main/counter-subgraph/subgraph-frontend)

Complete Program can be found at [counter-subgraph](https://github.com/4rjunc/evm-smart-contracts/tree/main/counter-subgraph)


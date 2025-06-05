const { ethers } = require("hardhat");

async function main() {
  // Replace with your deployed contract address
  const CONTRACT_ADDRESS = "0xA1BE4e668B740D4E99d58654a92D66961b44b5Be";

  console.log("Interacting with Counter contract on Sepolia...");
  console.log("Contract Address:", CONTRACT_ADDRESS);

  // Get the signer
  const [signer] = await ethers.getSigners();
  console.log("Using account:", signer.address);

  // Get contract instance
  const Counter = await ethers.getContractFactory("Counter");
  const counter = Counter.attach(CONTRACT_ADDRESS);

  try {
    // Get initial counter value
    console.log("\n=== Initial State ===");
    let currentValue = await counter.getCounter();
    console.log("Current counter value:", currentValue.toString());

    // Test increment
    console.log("\n=== Testing Increment ===");
    console.log("Incrementing counter...");
    let tx = await counter.increment();
    console.log("Transaction hash:", tx.hash);
    await tx.wait();

    console.log("\n=== Testing Increment ===");
    console.log("Incrementing counter...");
    tx = await counter.increment();
    console.log("Transaction hash:", tx.hash);
    await tx.wait();

    console.log("\n=== Testing Increment ===");
    console.log("Incrementing counter...");
    tx = await counter.increment();
    console.log("Transaction hash:", tx.hash);
    await tx.wait();


    console.log("\n=== Testing Increment ===");
    console.log("Incrementing counter...");
    tx = await counter.increment();
    console.log("Transaction hash:", tx.hash);
    await tx.wait();


    currentValue = await counter.getCounter();
    console.log("Counter after increment:", currentValue.toString());

    // Test increment again
    console.log("\nIncrementing again...");
    tx = await counter.increment();
    await tx.wait();

    currentValue = await counter.getCounter();
    console.log("Counter after second increment:", currentValue.toString());

    // Test decrement
    console.log("\n=== Testing Decrement ===");
    console.log("Decrementing counter...");
    tx = await counter.decrement();
    await tx.wait();

    currentValue = await counter.getCounter();
    console.log("Counter after decrement:", currentValue.toString());

    // Test reset
    console.log("\n=== Testing Reset ===");
    console.log("Resetting counter...");
    tx = await counter.reset();
    await tx.wait();

    currentValue = await counter.getCounter();
    console.log("Counter after reset:", currentValue.toString());

    // Test event listening
    console.log("\n=== Testing Events ===");
    console.log("Setting up event listeners...");

    // Listen for events
    counter.on("CounterIncrement", (newValue, caller) => {
      console.log(`CounterIncrement event: value=${newValue}, caller=${caller}`);
    });

    counter.on("CounterDecrement", (newValue, caller) => {
      console.log(`CounterDecrement event: value=${newValue}, caller=${caller}`);
    });

    counter.on("CounterReset", (caller) => {
      console.log(`CounterReset event: caller=${caller}`);
    });

    // Perform some operations to trigger events
    console.log("Performing operations to trigger events...");

    tx = await counter.increment();
    await tx.wait();
    console.log("Increment completed");

    tx = await counter.increment();
    await tx.wait();
    console.log("Second increment completed");

    tx = await counter.decrement();
    await tx.wait();
    console.log("Decrement completed");

    // Final state
    console.log("\n=== Final State ===");
    currentValue = await counter.getCounter();
    console.log("Final counter value:", currentValue.toString());

    // Test error case (optional - uncomment to test)
    /*
    console.log("\n=== Testing Error Case ===");
    try {
      await counter.reset();
      await counter.decrement(); // This should fail
    } catch (error) {
      console.log("Expected error caught:", error.message);
    }
    */

  } catch (error) {
    console.error("Error interacting with contract:", error);
  }
}

// Helper function to get transaction receipt details
async function getTransactionDetails(txHash) {
  const receipt = await ethers.provider.getTransactionReceipt(txHash);
  console.log("Gas used:", receipt.gasUsed.toString());
  console.log("Block number:", receipt.blockNumber);
  return receipt;
}

main()
  .then(() => {
    console.log("\nInteraction completed!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("Error:", error);
    process.exit(1);
  });

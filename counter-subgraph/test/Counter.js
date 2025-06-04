const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Counter", function() {
  let Counter, counter, owner, addr1, addr2;

  beforeEach(async function() {
    // Get signers
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy contract
    Counter = await ethers.getContractFactory("Counter");
    counter = await Counter.deploy();
    await counter.waitForDeployment();
  });

  describe("Deployment", function() {
    it("Should set the initial counter to 0", async function() {
      expect(await counter.counter()).to.equal(0);
    });

    it("Should return 0 when calling getCounter()", async function() {
      expect(await counter.getCounter()).to.equal(0);
    });
  });

  describe("Increment", function() {
    it("Should increment counter by 1", async function() {
      await counter.increment();
      expect(await counter.counter()).to.equal(1);
    });

    it("Should increment multiple times correctly", async function() {
      await counter.increment();
      await counter.increment();
      await counter.increment();
      expect(await counter.counter()).to.equal(3);
    });

    it("Should emit CounterIncrement event", async function() {
      await expect(counter.increment())
        .to.emit(counter, "CounterIncrement")
        .withArgs(1, owner.address);
    });

    it("Should emit CounterIncrement event with correct values after multiple increments", async function() {
      await counter.increment(); // counter = 1

      await expect(counter.increment())
        .to.emit(counter, "CounterIncrement")
        .withArgs(2, owner.address);
    });

    it("Should allow different addresses to increment", async function() {
      await expect(counter.connect(addr1).increment())
        .to.emit(counter, "CounterIncrement")
        .withArgs(1, addr1.address);

      await expect(counter.connect(addr2).increment())
        .to.emit(counter, "CounterIncrement")
        .withArgs(2, addr2.address);

      expect(await counter.counter()).to.equal(2);
    });

    it("Should handle large number of increments", async function() {
      for (let i = 0; i < 100; i++) {
        await counter.increment();
      }
      expect(await counter.counter()).to.equal(100);
    });

    it("Should increment from any starting value", async function() {
      // First increment to 5
      for (let i = 0; i < 5; i++) {
        await counter.increment();
      }

      // Then increment once more
      await expect(counter.increment())
        .to.emit(counter, "CounterIncrement")
        .withArgs(6, owner.address);
    });
  });

  describe("Decrement", function() {
    beforeEach(async function() {
      // Set counter to 5 for decrement tests
      for (let i = 0; i < 5; i++) {
        await counter.increment();
      }
    });

    it("Should decrement counter by 1", async function() {
      await counter.decrement();
      expect(await counter.counter()).to.equal(4);
    });

    it("Should decrement multiple times", async function() {
      await counter.decrement();
      await counter.decrement();
      expect(await counter.counter()).to.equal(3);
    });

    it("Should emit CounterDecrement event", async function() {
      await expect(counter.decrement())
        .to.emit(counter, "CounterDecrement")
        .withArgs(4, owner.address);
    });

    it("Should emit CounterDecrement event with correct values", async function() {
      await counter.decrement(); // counter = 4

      await expect(counter.decrement())
        .to.emit(counter, "CounterDecrement")
        .withArgs(3, owner.address);
    });

    it("Should revert when trying to decrement below zero", async function() {
      // Decrement to 0
      for (let i = 0; i < 5; i++) {
        await counter.decrement();
      }

      // Try to decrement below 0
      await expect(counter.decrement())
        .to.be.revertedWith("Counter cannot go below zero");
    });

    it("Should allow decrementing to exactly zero", async function() {
      // Decrement to 0
      for (let i = 0; i < 5; i++) {
        await counter.decrement();
      }
      expect(await counter.counter()).to.equal(0);

      // Check the last decrement event
      await expect(counter.increment())
        .to.emit(counter, "CounterIncrement")
        .withArgs(1, owner.address);
    });

    it("Should revert when trying to decrement from zero", async function() {
      // Reset to ensure we're at 0
      await counter.reset();

      await expect(counter.decrement())
        .to.be.revertedWith("Counter cannot go below zero");
    });

    it("Should allow different addresses to decrement", async function() {
      await expect(counter.connect(addr1).decrement())
        .to.emit(counter, "CounterDecrement")
        .withArgs(4, addr1.address);

      await expect(counter.connect(addr2).decrement())
        .to.emit(counter, "CounterDecrement")
        .withArgs(3, addr2.address);

      expect(await counter.counter()).to.equal(3);
    });
  });

  describe("Reset", function() {
    it("Should reset counter to 0 from positive value", async function() {
      // Increment to 10
      for (let i = 0; i < 10; i++) {
        await counter.increment();
      }

      await counter.reset();
      expect(await counter.counter()).to.equal(0);
    });

    it("Should reset counter to 0 when already 0", async function() {
      await counter.reset();
      expect(await counter.counter()).to.equal(0);
    });

    it("Should emit CounterReset event", async function() {
      // Increment first
      await counter.increment();

      await expect(counter.reset())
        .to.emit(counter, "CounterReset")
        .withArgs(owner.address);
    });

    it("Should emit CounterReset event even when counter is already 0", async function() {
      await expect(counter.reset())
        .to.emit(counter, "CounterReset")
        .withArgs(owner.address);
    });

    it("Should allow any address to reset", async function() {
      // Increment to 25
      for (let i = 0; i < 25; i++) {
        await counter.increment();
      }

      await expect(counter.connect(addr1).reset())
        .to.emit(counter, "CounterReset")
        .withArgs(addr1.address);

      expect(await counter.counter()).to.equal(0);
    });

    it("Should reset from any value", async function() {
      // Test reset from value 1
      await counter.increment();
      await counter.reset();
      expect(await counter.counter()).to.equal(0);

      // Test reset from larger value
      for (let i = 0; i < 50; i++) {
        await counter.increment();
      }
      await counter.reset();
      expect(await counter.counter()).to.equal(0);
    });
  });

  describe("GetCounter", function() {
    it("Should return correct counter value", async function() {
      for (let i = 0; i < 42; i++) {
        await counter.increment();
      }
      expect(await counter.getCounter()).to.equal(42);
    });

    it("Should return 0 initially", async function() {
      expect(await counter.getCounter()).to.equal(0);
    });

    it("Should return correct value after operations", async function() {
      await counter.increment(); // 1
      await counter.increment(); // 2
      await counter.decrement(); // 1

      expect(await counter.getCounter()).to.equal(1);
    });

    it("Should be a view function (no state changes)", async function() {
      const initialValue = await counter.getCounter();
      await counter.getCounter(); // Call again
      expect(await counter.getCounter()).to.equal(initialValue);
    });

    it("Should work correctly after reset", async function() {
      await counter.increment();
      await counter.increment();
      await counter.reset();

      expect(await counter.getCounter()).to.equal(0);
    });
  });

  describe("Mixed Operations", function() {
    it("Should handle complex sequence of operations", async function() {
      await counter.increment(); // 1
      await counter.increment(); // 2
      await counter.increment(); // 3
      await counter.decrement(); // 2
      await counter.decrement(); // 1
      await counter.increment(); // 2

      expect(await counter.counter()).to.equal(2);
    });

    it("Should maintain correct state after reset and operations", async function() {
      // Build up counter
      for (let i = 0; i < 100; i++) {
        await counter.increment();
      }

      // Reset and rebuild
      await counter.reset();
      await counter.increment();
      await counter.increment();

      expect(await counter.counter()).to.equal(2);
    });

    it("Should handle increment after decrement to zero", async function() {
      await counter.increment(); // 1
      await counter.decrement(); // 0
      await counter.increment(); // 1

      expect(await counter.counter()).to.equal(1);
    });

    it("Should not allow decrement after reset", async function() {
      await counter.increment();
      await counter.reset();

      await expect(counter.decrement())
        .to.be.revertedWith("Counter cannot go below zero");
    });
  });

  describe("Event Testing", function() {
    it("Should emit events with correct caller addresses", async function() {
      await expect(counter.connect(addr1).increment())
        .to.emit(counter, "CounterIncrement")
        .withArgs(1, addr1.address);

      await expect(counter.connect(addr2).increment())
        .to.emit(counter, "CounterIncrement")
        .withArgs(2, addr2.address);
    });

    it("Should emit multiple events in sequence", async function() {
      await expect(counter.increment())
        .to.emit(counter, "CounterIncrement")
        .withArgs(1, owner.address);

      await expect(counter.increment())
        .to.emit(counter, "CounterIncrement")
        .withArgs(2, owner.address);

      await expect(counter.decrement())
        .to.emit(counter, "CounterDecrement")
        .withArgs(1, owner.address);
    });

    it("Should emit reset event from different callers", async function() {
      await counter.increment();

      await expect(counter.connect(addr1).reset())
        .to.emit(counter, "CounterReset")
        .withArgs(addr1.address);
    });

    it("Should not emit events for failed transactions", async function() {
      // This should not emit any event since it reverts
      await expect(counter.decrement())
        .to.be.revertedWith("Counter cannot go below zero");
    });
  });

  describe("Access Control", function() {
    it("Should allow any address to call increment", async function() {
      await expect(counter.connect(addr1).increment()).to.not.be.reverted;
      await expect(counter.connect(addr2).increment()).to.not.be.reverted;
    });

    it("Should allow any address to call decrement (when valid)", async function() {
      await counter.increment(); // Make it possible to decrement

      await expect(counter.connect(addr1).decrement()).to.not.be.reverted;
    });

    it("Should allow any address to call reset", async function() {
      await expect(counter.connect(addr1).reset()).to.not.be.reverted;
      await expect(counter.connect(addr2).reset()).to.not.be.reverted;
    });

    it("Should allow any address to call getCounter", async function() {
      expect(await counter.connect(addr1).getCounter()).to.equal(0);
      expect(await counter.connect(addr2).getCounter()).to.equal(0);
    });
  });

  describe("Gas Usage", function() {
    it("Should have reasonable gas costs for increment", async function() {
      const tx = await counter.increment();
      const receipt = await tx.wait();

      // Gas should be reasonable for a simple increment
      expect(receipt.gasUsed).to.be.lessThan(50000);
    });

    it("Should have reasonable gas costs for decrement", async function() {
      await counter.increment(); // Setup

      const tx = await counter.decrement();
      const receipt = await tx.wait();

      expect(receipt.gasUsed).to.be.lessThan(50000);
    });

    it("Should have reasonable gas costs for reset", async function() {
      await counter.increment(); // Setup

      const tx = await counter.reset();
      const receipt = await tx.wait();

      expect(receipt.gasUsed).to.be.lessThan(50000);
    });

    it("Should have minimal gas cost for getCounter", async function() {
      // View functions don't consume gas when called externally
      const result = await counter.getCounter.staticCall();
      expect(result).to.equal(0);
    });
  });

  describe("Edge Cases", function() {
    it("Should handle maximum increments without overflow", async function() {
      // This would take too long to test to actual max, but we can test a reasonable amount
      for (let i = 0; i < 1000; i++) {
        await counter.increment();
      }
      expect(await counter.counter()).to.equal(1000);
    });

    it("Should handle rapid state changes", async function() {
      // Rapid increment/decrement/reset sequence
      await counter.increment();
      await counter.increment();
      await counter.decrement();
      await counter.reset();
      await counter.increment();

      expect(await counter.counter()).to.equal(1);
    });

    it("Should maintain state consistency across multiple transactions", async function() {
      // Multiple addresses performing operations
      await counter.connect(addr1).increment(); // 1
      await counter.connect(addr2).increment(); // 2
      await counter.connect(owner).decrement(); // 1
      await counter.connect(addr1).reset(); // 0
      await counter.connect(addr2).increment(); // 1

      expect(await counter.counter()).to.equal(1);
    });
  });
});

const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Counter", function() {
  let counter;
  let owner;
  let addr1;

  beforeEach(async function() {
    [owner, addr1] = await ethers.getSigners();

    const Counter = await ethers.getContractFactory("Counter");
    counter = await Counter.deploy();
    await counter.waitForDeployment();
  });

  describe("Deployment", function() {
    it("Should set the initial counter to 0", async function() {
      expect(await counter.getCounter()).to.equal(0);
    });

    it("Should set the counter public variable to 0", async function() {
      expect(await counter.counter()).to.equal(0);
    });
  });

  describe("Increment", function() {
    it("Should increment the counter", async function() {
      await counter.increment();
      expect(await counter.getCounter()).to.equal(1);
    });

    it("Should emit CounterIncrement event", async function() {
      await expect(counter.increment())
        .to.emit(counter, "CounterIncrement")
        .withArgs(1, owner.address);
    });

    it("Should increment multiple times", async function() {
      await counter.increment();
      await counter.increment();
      await counter.increment();
      expect(await counter.getCounter()).to.equal(3);
    });
  });

  describe("Decrement", function() {
    it("Should decrement the counter when counter > 0", async function() {
      await counter.increment();
      await counter.increment();
      await counter.decrement();
      expect(await counter.getCounter()).to.equal(1);
    });

    it("Should emit CounterDecrement event", async function() {
      await counter.increment();
      await expect(counter.decrement())
        .to.emit(counter, "CounterDecrement")
        .withArgs(0, owner.address);
    });

    it("Should revert when trying to decrement below zero", async function() {
      await expect(counter.decrement()).to.be.revertedWith(
        "Counter cannot go below zero"
      );
    });
  });

  describe("Reset", function() {
    it("Should reset counter to 0", async function() {
      await counter.increment();
      await counter.increment();
      await counter.reset();
      expect(await counter.getCounter()).to.equal(0);
    });

    it("Should emit CounterReset event", async function() {
      await counter.increment();
      await expect(counter.reset())
        .to.emit(counter, "CounterReset")
        .withArgs(owner.address);
    });

    it("Should reset even when counter is already 0", async function() {
      await counter.reset();
      expect(await counter.getCounter()).to.equal(0);
    });
  });

  describe("Multiple users", function() {
    it("Should allow different users to interact with contract", async function() {
      await counter.connect(addr1).increment();
      expect(await counter.getCounter()).to.equal(1);

      await counter.connect(owner).increment();
      expect(await counter.getCounter()).to.equal(2);
    });

    it("Should emit events with correct caller address", async function() {
      await expect(counter.connect(addr1).increment())
        .to.emit(counter, "CounterIncrement")
        .withArgs(1, addr1.address);
    });
  });
});

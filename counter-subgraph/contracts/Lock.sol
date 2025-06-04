// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Counter {
    
    uint256 public counter = 0;

    // EVENT
    event CounterIncrement(uint256 newValue, address indexed caller);
    event CounterDecrement(uint256 newValue, address indexed caller);
    event CounterReset(address indexed caller);
    

    function increment() public {
        counter++;

        // EMIT
        emit CounterIncrement(counter, msg.sender);
    }

    function decrement() public {
        require(counter > 0, "Counter cannot go below zero");
        counter--;

        // EMIT
        emit CounterDecrement(counter, msg.sender);
    }

    function reset() public {
        counter = 0;

        // EMIT
        emit CounterReset(msg.sender);
    }

    function getCounter() public view returns (uint256) {
        return counter;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract FallBackExample {
    uint256 public result;

    receive() external payable { 
        result += 1;
    }
}

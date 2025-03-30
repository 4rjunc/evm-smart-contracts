// SPDX-License-Identifier: MIT
// This is only for testing
pragma solidity  ^0.7.0;

contract SafeMathTester {
    uint8 public bigNumber = 255;

    function increasing() public  {
        bigNumber = bigNumber + 1;
    }
}

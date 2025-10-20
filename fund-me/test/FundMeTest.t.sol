// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundMeTest is Test {
    uint256 number = 1;
    FundMe fundMe;

    function setUp() external {
        fundMe = new FundMe();
        console.log("Hello");
        number = 2;
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        address owner = fundMe.i_owner();
        assertEq(owner, address(this));
    }
}

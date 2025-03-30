// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error NotOwner(); // Custom Erros

contract FundMe {
    uint256 public minimumUSD = 5e18;
    address[] public funders;
    mapping(address funders => uint256 amount) public addressToAmountFunded;
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    function fund()public  payable  {
        require(getConversionRate(msg.value) >= minimumUSD, "not enough");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] +=  msg.value;
    }

    function withdraw() public onlyOwner  {
        for (uint256 fundersIndex = 0; fundersIndex < funders.length; fundersIndex++) 
        {
            uint256 funder = funders[fundersIndex];
            addressToAmountFunded[funder] = 0;
        }
        // reset array 
        funders = new address[](0);

        // transfer 
        //payable(msg.sender).transfer(address(this).balance);
        // send
        //bool sendStatus = payable(msg.sender).send(address(this).balance);
        //require(sendStatus, "Send Failed");
        // call
        (bool callStatus, bytes callData) = payable(msg.sender).call{value:address(this).balance("")}(""); //recommended way
        require(callStatus, "Call Failed");
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface price =  AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        )= price.latestRoundData();
        return uint256(answer) * 1e10;
    }

    function getConversionRate(uint256 ethAmount) public  view  returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    modifier  onlyOwner(){
        //require(msg.sender == owner, "Only Owner");
        if(msg.sender != owner) { return NotOwner();}
        _;
    }
}

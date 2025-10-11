// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleStorage {
  uint256 myFavNumber;

  struct Person {
    uint256 favNumber;
    string name;
  }

  Person[] public listOfPeople;

  mapping (string=> uint256) public nameToFavNumber;

  function store(uint256 _favNumber) public {
    myFavNumber = _favNumber;
  }

  function retrieve() public view returns (uint256){
    return myFavNumber;
  }

  function addPerson(string memory _name, uint256 _favNumber) public{
    listOfPeople.push(Person(_favNumber, _name));
    nameToFavNumber[_name] = _favNumber;
  }
}


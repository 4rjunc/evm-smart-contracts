// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
//TaxToken
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TaxToken is ERC20 {

  // 10% Tax 
  uint taxDivisor = 10;

  constructor() ERC20("TaxToken", "TT") {
    
  }


  function mintToMe(uint amount) public {
    //msg.sender global var
    _mint(msg.sender, amount);
  }

  function transfer(address to, uint256 amount) public override returns (bool) {
  
      //1. Make use sender has enough money
      //2. Take 10% cut 
      //3. Send 90% to the reciepient
      uint balanceSender = balanceOf(msg.sender);
      require(balanceSender >= amount, "ERC20 not enough");

      // Solidity does't support floatings

      uint taxAmount = amount / taxDivisor;
      uint transferAmount = amount - taxAmount;


      // here the 10% tokens are burned 
      // more transaction happens more reduction of  the supply 
      // hypothetically the demands stays the same price goes up

      _transfer(msg.sender, to, transferAmount);
      _transfer(msg.sender, 0x000000000000000000000000000000000000dEaD, taxAmount); // can change the address with our wallet address, for now its sending to dead address

      emit Transfer(msg.sender, to, amount);

      return true; 
    }

}

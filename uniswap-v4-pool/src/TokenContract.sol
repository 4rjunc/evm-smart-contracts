// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenContract is ERC20, Ownable {
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10 ** 18; // 1 Billion tokens
    uint256 public constant REQUIRED_ETH = 3.5 ether;

    bool public ethReceived;

    event ETHReceived(address indexed from, uint256 amount);
    event ETHWithdrawn(address indexed to, uint256 amount);

    constructor() ERC20("MyToken", "MTK") Ownable(msg.sender) {
        // Mint 1 billion tokens to the contract deployer
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    /**
     * @dev Function to receive exactly 3.5 ETH
     * Can only be called once
     */
    function receiveETH() external payable {
        require(!ethReceived, "ETH already received");
        require(msg.value == REQUIRED_ETH, "Must send exactly 3.5 ETH");

        ethReceived = true;
        emit ETHReceived(msg.sender, msg.value);
    }

    /**
     * @dev Owner-only function to withdraw ETH from contract
     * @param amount Amount of ETH to withdraw (in wei)
     */
    function withdrawETH(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");

        (bool success,) = payable(owner()).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit ETHWithdrawn(owner(), amount);
    }

    /**
     * @dev Withdraw all ETH from contract
     */
    function withdrawAllETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");

        (bool success,) = payable(owner()).call{value: balance}("");
        require(success, "ETH transfer failed");

        emit ETHWithdrawn(owner(), balance);
    }

    /**
     * @dev Get contract's ETH balance
     */
    function getETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Fallback function to reject direct ETH transfers
     */
    receive() external payable {
        revert("Use receiveETH() function");
    }
}

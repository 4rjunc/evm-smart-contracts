// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TaxToken.sol";

contract TaxTokenTest is Test {
    TaxToken public taxToken;
    address public user1;
    address public user2;
    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant INITIAL_MINT = 1000 * 10**18; // 1000 tokens with 18 decimals

    function setUp() public {
        taxToken = new TaxToken();
        
        user1 = address(0x1);
        user2 = address(0x2);
        
        // Give user1 some initial tokens
        vm.startPrank(user1);
        taxToken.mintToMe(INITIAL_MINT);
        vm.stopPrank();
    }

    function testInitialSetup() public {
        assertEq(taxToken.name(), "TaxToken");
        assertEq(taxToken.symbol(), "TT");
        assertEq(taxToken.decimals(), 18);
        assertEq(taxToken.balanceOf(user1), INITIAL_MINT);
    }

    function testMintToMe() public {
        uint256 mintAmount = 500 * 10**18;
        
        // Test minting as user2
        vm.startPrank(user2);
        
        uint256 balanceBefore = taxToken.balanceOf(user2);
        taxToken.mintToMe(mintAmount);
        uint256 balanceAfter = taxToken.balanceOf(user2);
        
        assertEq(balanceAfter - balanceBefore, mintAmount);
        vm.stopPrank();
    }

    function testTransferWithTax() public {
        uint256 transferAmount = 100 * 10**18;
        uint256 expectedTaxAmount = transferAmount / 10; // 10% tax
        uint256 expectedReceivedAmount = transferAmount - expectedTaxAmount;
        
        uint256 user1BalanceBefore = taxToken.balanceOf(user1);
        uint256 user2BalanceBefore = taxToken.balanceOf(user2);
        uint256 deadAddressBalanceBefore = taxToken.balanceOf(DEAD_ADDRESS);
        
        // Transfer from user1 to user2
        vm.startPrank(user1);
        taxToken.transfer(user2, transferAmount);
        vm.stopPrank();
        
        uint256 user1BalanceAfter = taxToken.balanceOf(user1);
        uint256 user2BalanceAfter = taxToken.balanceOf(user2);
        uint256 deadAddressBalanceAfter = taxToken.balanceOf(DEAD_ADDRESS);
        
        // Check user1's balance decreased by full amount
        assertEq(user1BalanceBefore - user1BalanceAfter, transferAmount);
        
        // Check user2 received 90%
        assertEq(user2BalanceAfter - user2BalanceBefore, expectedReceivedAmount);
        
        // Check dead address received 10%
        assertEq(deadAddressBalanceAfter - deadAddressBalanceBefore, expectedTaxAmount);
    }

    function testTransferInsufficientBalance() public {
        uint256 transferAmount = INITIAL_MINT + 1 * 10**18; // More than user1 has
        
        // Try to transfer more than available balance
        vm.startPrank(user1);
        vm.expectRevert("ERC20 not enough");
        taxToken.transfer(user2, transferAmount);
        vm.stopPrank();
    }

    function testMultipleTransfers() public {
        uint256 transferAmount = 100 * 10**18;
        
        // First transfer: user1 -> user2
        vm.startPrank(user1);
        taxToken.transfer(user2, transferAmount);
        vm.stopPrank();
        
        // Second transfer: user2 -> user1
        uint256 user2BalanceAfterFirstTransfer = taxToken.balanceOf(user2);
        uint256 user1BalanceAfterFirstTransfer = taxToken.balanceOf(user1);
        uint256 deadAddressBalanceAfterFirstTransfer = taxToken.balanceOf(DEAD_ADDRESS);
        
        vm.startPrank(user2);
        taxToken.transfer(user1, user2BalanceAfterFirstTransfer);
        vm.stopPrank();
        
        uint256 expectedTaxAmount = user2BalanceAfterFirstTransfer / 10;
        uint256 expectedReceivedAmount = user2BalanceAfterFirstTransfer - expectedTaxAmount;
        
        // Check user2's balance is 0 after second transfer
        assertEq(taxToken.balanceOf(user2), 0);
        
        // Check user1 received 90% of user2's balance
        assertEq(taxToken.balanceOf(user1), user1BalanceAfterFirstTransfer + expectedReceivedAmount);
        
        // Check dead address received additional 10%
        assertEq(taxToken.balanceOf(DEAD_ADDRESS), deadAddressBalanceAfterFirstTransfer + expectedTaxAmount);
    }

    function testTransferEmitsCorrectEvent() public {
        uint256 transferAmount = 100 * 10**18;
        
        vm.startPrank(user1);
        
        // Check that the Transfer event is emitted with the correct parameters
        vm.expectEmit(true, true, true, true);
        
        taxToken.transfer(user2, transferAmount);
        vm.stopPrank();
    }

    // Test for large transfers with rounding
    function testLargeTransferWithRounding() public {
        uint256 largeAmount = 1_000_000 * 10**18;
        
        // Mint large amount to user1
        vm.startPrank(user1);
        taxToken.mintToMe(largeAmount);
        vm.stopPrank();
        
        uint256 transferAmount = 123_456_789; // Small odd amount
        uint256 expectedTaxAmount = transferAmount / 10;
        uint256 expectedReceivedAmount = transferAmount - expectedTaxAmount;
        
        vm.startPrank(user1);
        taxToken.transfer(user2, transferAmount);
        vm.stopPrank();
        
        assertEq(taxToken.balanceOf(user2), expectedReceivedAmount);
        // Verify precision is maintained
        assertEq(expectedTaxAmount + expectedReceivedAmount, transferAmount);
    }
}

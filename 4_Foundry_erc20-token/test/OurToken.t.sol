// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {OurToken} from "../src/OurToken.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OurTokenTest is Test {
    OurToken public ourToken;

    address public deployerAddress;
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    uint256 public constant STARTING_BALANCE = 100 ether;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setUp() public {
        // We need to deploy directly without using the deployer script
        // This ensures the msg.sender (which will be the test contract) gets the tokens
        deployerAddress = address(this);
        ourToken = new OurToken(STARTING_BALANCE);
    }

    function testTokenNameAndSymbol() public view {
        assertEq(ourToken.name(), "OurToken");
        assertEq(ourToken.symbol(), "OT");
    }

    function testInitialSupply() public view {
        assertEq(ourToken.totalSupply(), STARTING_BALANCE);
        assertEq(ourToken.balanceOf(deployerAddress), STARTING_BALANCE);
    }

    function testUserCanTransferTokens() public {
        uint256 transferAmount = 10 ether;
        
        // Transfer tokens to user1
        assertTrue(ourToken.transfer(user1, transferAmount));
        
        // Check balances after transfer
        assertEq(ourToken.balanceOf(deployerAddress), STARTING_BALANCE - transferAmount);
        assertEq(ourToken.balanceOf(user1), transferAmount);
    }

    function testTransferFailsWithInsufficientBalance() public {
        uint256 transferAmount = STARTING_BALANCE + 1 ether; // More than the deployer has
        
        vm.startPrank(user1); // user1 has no tokens initially
        vm.expectRevert();
        ourToken.transfer(user2, transferAmount);
        vm.stopPrank();
    }

    function testAllowanceAndTransferFrom() public {
        uint256 allowanceAmount = 10 ether;
        uint256 transferAmount = 5 ether;
        
        // Approve user1 to spend tokens
        assertTrue(ourToken.approve(user1, allowanceAmount));
        
        // Check allowance
        assertEq(ourToken.allowance(deployerAddress, user1), allowanceAmount);
        
        // User1 transfers tokens from deployer to user2
        vm.startPrank(user1);
        assertTrue(ourToken.transferFrom(deployerAddress, user2, transferAmount));
        vm.stopPrank();
        
        // Check balances and allowance after transfer
        assertEq(ourToken.balanceOf(deployerAddress), STARTING_BALANCE - transferAmount);
        assertEq(ourToken.balanceOf(user2), transferAmount);
        assertEq(ourToken.allowance(deployerAddress, user1), allowanceAmount - transferAmount);
    }

    function testTransferFromFailsWithInsufficientAllowance() public {
        uint256 allowanceAmount = 10 ether;
        uint256 transferAmount = 20 ether; // More than the allowance
        
        // Approve user1 to spend tokens
        ourToken.approve(user1, allowanceAmount);
        
        // User1 tries to transfer more than allowed
        vm.startPrank(user1);
        vm.expectRevert();
        ourToken.transferFrom(deployerAddress, user2, transferAmount);
        vm.stopPrank();
    }

    function testTransferToZeroAddress() public {
        uint256 transferAmount = 10 ether;
        
        // Try to transfer tokens to zero address
        vm.expectRevert();
        ourToken.transfer(address(0), transferAmount);
    }

    function testTransferFromToZeroAddress() public {
        uint256 allowanceAmount = 10 ether;
        
        // Approve user1 to spend tokens
        ourToken.approve(user1, allowanceAmount);
        
        // User1 tries to transfer tokens to zero address
        vm.startPrank(user1);
        vm.expectRevert();
        ourToken.transferFrom(deployerAddress, address(0), allowanceAmount);
        vm.stopPrank();
    }

    function testApproveZeroAddress() public {
        uint256 approveAmount = 10 ether;
        
        // Try to approve zero address
        vm.expectRevert();
        ourToken.approve(address(0), approveAmount);
    }

    function testTransferEmitsEvent() public {
        uint256 transferAmount = 10 ether;
        
        // Expect Transfer event to be emitted
        vm.expectEmit(true, true, false, true);
        emit Transfer(deployerAddress, user1, transferAmount);
        ourToken.transfer(user1, transferAmount);
    }

    function testApproveEmitsEvent() public {
        uint256 approveAmount = 10 ether;
        
        // Expect Approval event to be emitted
        vm.expectEmit(true, true, false, true);
        emit Approval(deployerAddress, user1, approveAmount);
        ourToken.approve(user1, approveAmount);
    }

    function testMultipleTransfers() public {
        uint256 transferAmount1 = 10 ether;
        uint256 transferAmount2 = 5 ether;
        
        // Transfer tokens to user1
        ourToken.transfer(user1, transferAmount1);
        
        // User1 transfers tokens to user2
        vm.startPrank(user1);
        ourToken.transfer(user2, transferAmount2);
        vm.stopPrank();
        
        // Check final balances
        assertEq(ourToken.balanceOf(deployerAddress), STARTING_BALANCE - transferAmount1);
        assertEq(ourToken.balanceOf(user1), transferAmount1 - transferAmount2);
        assertEq(ourToken.balanceOf(user2), transferAmount2);
    }

    function testApproveAndIncreaseAllowance() public {
        uint256 initialAllowance = 10 ether;
        uint256 additionalAllowance = 5 ether;
        
        // Approve user1 to spend tokens
        ourToken.approve(user1, initialAllowance);
        
        // Check initial allowance
        assertEq(ourToken.allowance(deployerAddress, user1), initialAllowance);
        
        // Increase allowance for user1
        ourToken.approve(user1, initialAllowance + additionalAllowance);
        
        // Check increased allowance
        assertEq(ourToken.allowance(deployerAddress, user1), initialAllowance + additionalAllowance);
    }

    function testDecimalsValue() public view {
        assertEq(ourToken.decimals(), 18);
    }

    function testTransferZeroAmount() public {
        // Transfer 0 tokens to user1
        assertTrue(ourToken.transfer(user1, 0));
        
        // Check balances remain unchanged
        assertEq(ourToken.balanceOf(deployerAddress), STARTING_BALANCE);
        assertEq(ourToken.balanceOf(user1), 0);
    }

    function testApproveZeroAmount() public {
        // Approve user1 to spend 0 tokens
        assertTrue(ourToken.approve(user1, 0));
        
        // Check allowance is 0
        assertEq(ourToken.allowance(deployerAddress, user1), 0);
    }

    function testTransferFromZeroAmount() public {
        uint256 allowanceAmount = 10 ether;
        
        // Approve user1 to spend tokens
        ourToken.approve(user1, allowanceAmount);
        
        // User1 transfers 0 tokens from deployer to user2
        vm.startPrank(user1);
        assertTrue(ourToken.transferFrom(deployerAddress, user2, 0));
        vm.stopPrank();
        
        // Check balances remain unchanged and allowance is unchanged
        assertEq(ourToken.balanceOf(deployerAddress), STARTING_BALANCE);
        assertEq(ourToken.balanceOf(user2), 0);
        assertEq(ourToken.allowance(deployerAddress, user1), allowanceAmount);
    }

    function testTransferToSelf() public {
        uint256 transferAmount = 10 ether;
        
        // Transfer tokens to self
        assertTrue(ourToken.transfer(deployerAddress, transferAmount));
        
        // Check balance remains unchanged
        assertEq(ourToken.balanceOf(deployerAddress), STARTING_BALANCE);
    }

    function testTransferFromToSelf() public {
        uint256 allowanceAmount = 10 ether;
        
        // Approve user1 to spend tokens
        ourToken.approve(user1, allowanceAmount);
        
        // User1 transfers tokens from deployer to user1
        vm.startPrank(user1);
        assertTrue(ourToken.transferFrom(deployerAddress, user1, allowanceAmount));
        vm.stopPrank();
        
        // Check balances and allowance
        assertEq(ourToken.balanceOf(deployerAddress), STARTING_BALANCE - allowanceAmount);
        assertEq(ourToken.balanceOf(user1), allowanceAmount);
        assertEq(ourToken.allowance(deployerAddress, user1), 0);
    }

    function testMaxApproval() public {
        uint256 maxApproval = type(uint256).max;
        
        // Approve user1 to spend max tokens
        assertTrue(ourToken.approve(user1, maxApproval));
        
        // Check allowance is max
        assertEq(ourToken.allowance(deployerAddress, user1), maxApproval);
        
        // User1 transfers tokens from deployer to user2
        uint256 transferAmount = 10 ether;
        vm.startPrank(user1);
        assertTrue(ourToken.transferFrom(deployerAddress, user2, transferAmount));
        vm.stopPrank();
        
        // Check balances and allowance (allowance should still be max)
        assertEq(ourToken.balanceOf(deployerAddress), STARTING_BALANCE - transferAmount);
        assertEq(ourToken.balanceOf(user2), transferAmount);
        assertEq(ourToken.allowance(deployerAddress, user1), maxApproval);
    }
} 
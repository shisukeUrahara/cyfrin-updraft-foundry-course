// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    DeployFundMe deployFundMe;
    // Create test addresses
    address USER = makeAddr("user");
    address ANOTHER_USER = makeAddr("anotherUser");

    // Set initial balance for test users
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // Deploy the contract directly instead of using DeployFundMe
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();

        // Fund test users with ETH
        vm.deal(USER, STARTING_BALANCE);
        vm.deal(ANOTHER_USER, STARTING_BALANCE);
    }

    // ==================== UNIT TESTS ====================

    // Test if the minimum USD amount is set correctly
    function testMinimumUsdIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    // Test if the owner is set correctly
    function testOwnerIsDeployer() public view {
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }
}

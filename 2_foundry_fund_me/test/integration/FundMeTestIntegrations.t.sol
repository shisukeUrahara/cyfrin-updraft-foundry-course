// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";
import {FundMe} from "../../src/FundMe.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract InteractionsTest is StdCheats, Test {
    FundMe public fundMe;
    HelperConfig public helperConfig;

    uint256 public constant SEND_VALUE = 0.1 ether; // just a value to make sure we are sending enough!
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant GAS_PRICE = 1;

    address public constant USER = address(1);

    // Add a receive function to accept ETH
    receive() external payable {}

    // uint256 public constant SEND_VALUE = 1e18;
    // uint256 public constant SEND_VALUE = 1_000_000_000_000_000_000;
    // uint256 public constant SEND_VALUE = 1000000000000000000;

    function setUp() external {
        helperConfig = new HelperConfig();
        fundMe = new FundMe(
            helperConfig.getConfigByChainId(block.chainid).priceFeed
        );

        vm.deal(USER, STARTING_USER_BALANCE);
    }

    function testUserCanFundAndOwnerWithdraw() public {
        // Get the owner address
        address owner = fundMe.getOwner();

        // Fund the contract as a user
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        // Verify funding was successful
        assertEq(address(fundMe).balance, SEND_VALUE);

        // Now withdraw as the owner (not using a separate contract)
        vm.prank(owner);
        fundMe.withdraw();

        // Verify withdrawal was successful
        assertEq(address(fundMe).balance, 0);
    }
}

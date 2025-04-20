// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/Interfaces/IRebaseToken.sol";
contract RebaseTokenTest is Test {
    RebaseToken rebaseToken;
    Vault vault;
    address public owner = makeAddr("owner");
    address public user = makeAddr("user");

    function setUp() public {
        vm.startPrank(owner);
        rebaseToken = new RebaseToken();
        vault = new Vault(address(rebaseToken));
        rebaseToken.grantRole(rebaseToken.MINT_AND_BURN_ROLE(), address(vault));
        // add some funds to the vault
        // vm.deal(address(vault), 100 ether);
        vm.stopPrank();
    }

    // a test case to test name
    function testName() public view {
        assertEq(rebaseToken.name(), "RebaseToken");
    }

    // a test case to test symbol
    function testSymbol() public view {
        assertEq(rebaseToken.symbol(), "RBT");
    }

    // this is a fuzz test with a fuzzed deposit amount
    function testDepositLinear(uint256 _depositAmount) public {
        vm.startPrank(user);

        // we want to run only the case where the deposit amount is greater than 1e5
        // vm.assume(_depositAmount > 1e5);

        //  this is when we manually adjust the deposit amount to be within a range for the fuzz tests
        _depositAmount = bound(_depositAmount, 1e5, type(uint96).max);
        vm.deal(user, _depositAmount);
        vault.deposit{value: _depositAmount}();

        // Check balance after 1 day
        vm.warp(block.timestamp + 1 days);
        uint256 balanceAfterDay1 = rebaseToken.balanceOf(user);

        // Check balance after 2 days
        vm.warp(block.timestamp + 1 days);
        uint256 balanceAfterDay2 = rebaseToken.balanceOf(user);

        // Check balance after 3 days
        vm.warp(block.timestamp + 1 days);
        uint256 balanceAfterDay3 = rebaseToken.balanceOf(user);

        // Calculate and verify interest is approximately linear
        uint256 interestDay1 = balanceAfterDay1 - _depositAmount;
        uint256 interestDay2 = balanceAfterDay2 - balanceAfterDay1;
        uint256 interestDay3 = balanceAfterDay3 - balanceAfterDay2;

        // Use assertApproxEqAbs to allow for small rounding differences
        assertApproxEqAbs(
            interestDay1,
            interestDay2,
            1,
            "Interest should be approximately linear"
        );
        assertApproxEqAbs(
            interestDay2,
            interestDay3,
            1,
            "Interest should be approximately linear"
        );
        vm.stopPrank();
    }
}

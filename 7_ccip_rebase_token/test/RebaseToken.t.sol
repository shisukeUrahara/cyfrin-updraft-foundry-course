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
        vm.deal(address(vault), 100 ether);
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
}

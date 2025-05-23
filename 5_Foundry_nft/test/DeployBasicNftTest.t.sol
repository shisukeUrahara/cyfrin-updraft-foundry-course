// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployBasicNft} from "../script/DeployBasicNft.s.sol";
import {BasicNft} from "../src/BasicNft.sol";

contract DeployBasicNftTest is Test {
    DeployBasicNft public deployer;

    function setUp() public {
        deployer = new DeployBasicNft();
    }

    function testDeployBasicNft() public {
        BasicNft basicNft = deployer.run();

        // Verify the contract was deployed
        assertTrue(address(basicNft) != address(0));

        // Verify the name and symbol
        assertEq(basicNft.name(), "Dogie");
        assertEq(basicNft.symbol(), "DOG");
    }
}

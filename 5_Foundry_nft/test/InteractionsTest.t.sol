// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {MintBasicNft} from "../script/Interactions.s.sol";
import {DeployBasicNft} from "../script/DeployBasicNft.s.sol";
import {BasicNft} from "../src/BasicNft.sol";

contract InteractionsTest is Test {
    MintBasicNft public minter;
    BasicNft public basicNft;
    string public constant PUG_URI =
        "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";

    function setUp() public {
        DeployBasicNft deployer = new DeployBasicNft();
        basicNft = deployer.run();
        minter = new MintBasicNft();
    }

    function testMintBasicNft() public {
        uint256 startingTokenCount = basicNft.getTokenCounter();
        minter.mintNftOnContract(address(basicNft));

        assertEq(basicNft.getTokenCounter(), startingTokenCount + 1);
        assertEq(basicNft.tokenURI(startingTokenCount), PUG_URI);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {BasicNft} from "../src/BasicNft.sol";
import {Test, console2} from "forge-std/Test.sol";
import {DeployBasicNft} from "../script/DeployBasicNft.s.sol";

contract BasicNftTest is Test {
    string constant NFT_NAME = "Dogie";
    string constant NFT_SYMBOL = "DOG";
    BasicNft public basicNft;
    address public constant USER = address(1);
    address public constant USER2 = address(2);

    string public constant PUG_URI =
        "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4jqhy4gkaheg4/?filename=0-PUG.json";
    string public constant SHIBA_URI =
        "ipfs://bafybeicutklh5mfepmqwgqnm7chkp4hi3yldn3caup6akgondaw3d4ln5a/?filename=1-SHIBA_INU.json";

    function setUp() public {
        // Deploy a fresh contract for each test
        basicNft = new BasicNft();
    }

    function testInitializedCorrectly() public view {
        assert(
            keccak256(abi.encodePacked(basicNft.name())) ==
                keccak256(abi.encodePacked((NFT_NAME)))
        );
        assert(
            keccak256(abi.encodePacked(basicNft.symbol())) ==
                keccak256(abi.encodePacked((NFT_SYMBOL)))
        );
    }

    function testGetTokenCounter() public {
        // Should start at 0
        assertEq(basicNft.getTokenCounter(), 0);

        // Mint a token and check if counter increments
        vm.prank(USER);
        basicNft.mintNft(PUG_URI);
        assertEq(basicNft.getTokenCounter(), 1);

        // Mint another token and check again
        vm.prank(USER);
        basicNft.mintNft(SHIBA_URI);
        assertEq(basicNft.getTokenCounter(), 2);
    }

    function testCanMintAndHaveABalance() public {
        vm.prank(USER);
        basicNft.mintNft(PUG_URI);

        assertEq(basicNft.balanceOf(USER), 1);

        // Mint another token and check balance again
        vm.prank(USER);
        basicNft.mintNft(SHIBA_URI);
        assertEq(basicNft.balanceOf(USER), 2);

        // Test minting from a different user
        vm.prank(USER2);
        basicNft.mintNft(PUG_URI);
        assertEq(basicNft.balanceOf(USER2), 1);
    }

    function testTokenURIIsCorrect() public {
        vm.prank(USER);
        basicNft.mintNft(PUG_URI);

        assertEq(basicNft.tokenURI(0), PUG_URI);

        // Test with another token
        vm.prank(USER);
        basicNft.mintNft(SHIBA_URI);
        assertEq(basicNft.tokenURI(1), SHIBA_URI);
    }

    function testTokenURIFailsForNonexistentToken() public {
        // Should revert when querying tokenURI for a non-existent token
        // The ERC721 base contract throws ERC721NonexistentToken before our custom error is reached
        vm.expectRevert(
            abi.encodeWithSignature("ERC721NonexistentToken(uint256)", 0)
        );
        basicNft.tokenURI(0);
    }

    function testOwnership() public {
        // Mint two NFTs, one for each user
        vm.prank(USER);
        basicNft.mintNft(PUG_URI);

        vm.prank(USER2);
        basicNft.mintNft(SHIBA_URI);

        // Check ownership
        assertEq(basicNft.ownerOf(0), USER);
        assertEq(basicNft.ownerOf(1), USER2);
    }

    function testMintMultipleTokensToSameOwner() public {
        // Mint 3 NFTs to the same owner
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(USER);
            basicNft.mintNft(string(abi.encodePacked(PUG_URI, i)));
        }

        // Check total supply and owner balance
        assertEq(basicNft.getTokenCounter(), 3);
        assertEq(basicNft.balanceOf(USER), 3);
    }
}

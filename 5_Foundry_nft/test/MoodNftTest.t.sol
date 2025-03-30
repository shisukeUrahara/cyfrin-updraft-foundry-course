// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DeployMoodNft} from "../script/DeployMoodNft.s.sol";
import {MoodNft} from "../src/MoodNft.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {MintBasicNft} from "../script/Interactions.s.sol";

contract MoodNftTest is Test {
    string constant NFT_NAME = "Mood NFT";
    string constant NFT_SYMBOL = "MN";
    MoodNft public moodNft;
    DeployMoodNft public deployer;
    address public deployerAddress;

    // These URIs will be set in setUp() based on our actual SVG files
    string public HAPPY_MOOD_URI;
    string public SAD_MOOD_URI;
    string public constant HAPPY_SVG_URI = "data:image/svg+xml;base64,happy";
    string public constant SAD_SVG_URI = "data:image/svg+xml;base64,sad";

    address public constant USER = address(1);
    address public constant OTHER_USER = address(2);
    address public constant APPROVED_USER = address(3);

    function setUp() public {
        deployer = new DeployMoodNft();

        string memory sadSvg = vm.readFile("./img/sad.svg");
        string memory happySvg = vm.readFile("./img/happy.svg");

        moodNft = new MoodNft(SAD_SVG_URI, HAPPY_SVG_URI);

        // Mint a token first
        vm.prank(USER);
        moodNft.mintNft();

        // Set the URIs based on our actual SVG files
        HAPPY_MOOD_URI = moodNft.tokenURI(0); // This will give us the happy URI
        vm.prank(USER);
        moodNft.flipMood(0); // Flip to sad to get the sad URI
        SAD_MOOD_URI = moodNft.tokenURI(0);
        vm.prank(USER);
        moodNft.flipMood(0); // Flip back to happy
    }

    function testInitializedCorrectly() public view {
        assert(
            keccak256(abi.encodePacked(moodNft.name())) ==
                keccak256(abi.encodePacked((NFT_NAME)))
        );
        assert(
            keccak256(abi.encodePacked(moodNft.symbol())) ==
                keccak256(abi.encodePacked((NFT_SYMBOL)))
        );
    }

    function testCanMintAndHaveABalance() public {
        // Get initial balance
        uint256 initialBalance = moodNft.balanceOf(USER);

        vm.prank(USER);
        moodNft.mintNft();

        // Balance should increase by 1
        assertEq(moodNft.balanceOf(USER), initialBalance + 1);
    }

    function testTokenURIDefaultIsCorrectlySet() public {
        vm.prank(USER);
        moodNft.mintNft();

        assert(
            keccak256(abi.encodePacked(moodNft.tokenURI(0))) ==
                keccak256(abi.encodePacked(HAPPY_MOOD_URI))
        );
    }

    function testFlipTokenToSad() public {
        vm.prank(USER);
        moodNft.mintNft();

        vm.prank(USER);
        moodNft.flipMood(0);

        assert(
            keccak256(abi.encodePacked(moodNft.tokenURI(0))) ==
                keccak256(abi.encodePacked(SAD_MOOD_URI))
        );
    }

    function testEventRecordsCorrectTokenIdOnMinting() public {
        uint256 currentAvailableTokenId = moodNft.getTokenCounter();

        vm.prank(USER);
        vm.recordLogs();
        moodNft.mintNft();
        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 tokenId_proto = entries[1].topics[1];
        uint256 tokenId = uint256(tokenId_proto);

        assertEq(tokenId, currentAvailableTokenId);
    }

    function testGetSvgUris() public {
        assertEq(moodNft.getHappySVG(), HAPPY_SVG_URI);
        assertEq(moodNft.getSadSVG(), SAD_SVG_URI);
    }

    function testTokenCounter() public {
        uint256 startingCounter = moodNft.getTokenCounter();

        vm.prank(USER);
        moodNft.mintNft();

        assertEq(moodNft.getTokenCounter(), startingCounter + 1);
    }

    function testFlipMoodWithApprovedUser() public {
        uint256 tokenId = 0;

        // Approve OTHER_USER to manage the token
        vm.prank(USER);
        moodNft.approve(APPROVED_USER, tokenId);

        // OTHER_USER should be able to flip the mood
        vm.prank(APPROVED_USER);
        moodNft.flipMood(tokenId);

        // Token should be in SAD state
        assert(
            keccak256(abi.encodePacked(moodNft.tokenURI(tokenId))) ==
                keccak256(abi.encodePacked(SAD_MOOD_URI))
        );
    }

    function testCantFlipMoodIfNotOwnerOrApproved() public {
        uint256 tokenId = 0;

        // Try to flip mood as unauthorized user
        vm.prank(OTHER_USER);
        vm.expectRevert(MoodNft.MoodNft__CantFlipMoodIfNotOwner.selector);
        moodNft.flipMood(tokenId);
    }

    function testCantGetTokenURIForNonexistentToken() public {
        vm.expectRevert();
        moodNft.tokenURI(999);
    }

    function testFlipMoodBackAndForth() public {
        uint256 tokenId = 0;
        string memory initialUri = moodNft.tokenURI(tokenId);

        // Flip to sad
        vm.prank(USER);
        moodNft.flipMood(tokenId);
        string memory sadUri = moodNft.tokenURI(tokenId);
        assert(
            keccak256(abi.encodePacked(sadUri)) !=
                keccak256(abi.encodePacked(initialUri))
        );

        // Flip back to happy
        vm.prank(USER);
        moodNft.flipMood(tokenId);
        string memory happyUri = moodNft.tokenURI(tokenId);
        assert(
            keccak256(abi.encodePacked(happyUri)) ==
                keccak256(abi.encodePacked(initialUri))
        );
    }
}

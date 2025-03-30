// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployMoodNft} from "../script/DeployMoodNft.s.sol";
import {MoodNft} from "../src/MoodNft.sol";

contract DeployMoodNftTest is Test {
    DeployMoodNft public deployer;

    function setUp() public {
        deployer = new DeployMoodNft();
    }

    function testConvertSvgToImageUri() public {
        string
            memory testSvg = '<svg width="500" height="500" viewBox="0 0 285 350" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill="black" d="M150,0,L75,200,L225,200,Z"></path></svg>';
        string memory expectedStart = "data:image/svg+xml;base64,";

        string memory imageUri = deployer.svgToImageURI(testSvg);

        // Verify it starts with the correct prefix
        assertTrue(bytes(imageUri).length > bytes(expectedStart).length);
        assertEq(
            keccak256(
                abi.encodePacked(
                    substring(imageUri, 0, bytes(expectedStart).length)
                )
            ),
            keccak256(abi.encodePacked(expectedStart))
        );
    }

    function testDeployMoodNft() public {
        MoodNft moodNft = deployer.run();

        // Verify the contract was deployed
        assertTrue(address(moodNft) != address(0));

        // Verify the name and symbol
        assertEq(moodNft.name(), "Mood NFT");
        assertEq(moodNft.symbol(), "MN");
    }

    // Helper function to get a substring
    function substring(
        string memory str,
        uint256 startIndex,
        uint256 length
    ) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(length);
        for (uint i = 0; i < length; i++) {
            result[i] = strBytes[startIndex + i];
        }
        return string(result);
    }
}

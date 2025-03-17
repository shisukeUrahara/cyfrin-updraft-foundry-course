// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {OurToken} from "../src/OurToken.sol";

contract DeployOurToken is Script {
    uint256 public constant INITIAL_SUPPLY = 100 ether;

    function run() public returns (OurToken) {
        vm.startBroadcast();
        OurToken token = new OurToken(INITIAL_SUPPLY);
        vm.stopBroadcast();
        return token;
    }
    
    // This function is used for testing
    function deployForTest() public returns (OurToken) {
        // No broadcast needed for testing
        OurToken token = new OurToken(INITIAL_SUPPLY);
        return token;
    }
}

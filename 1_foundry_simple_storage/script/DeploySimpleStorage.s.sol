// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";

contract DeploySimpleStorage is Script {
    function run() external returns (SimpleStorage) {
        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the SimpleStorage contract
        SimpleStorage simpleStorage = new SimpleStorage();

        // Stop broadcasting transactions
        vm.stopBroadcast();

        return simpleStorage;
    }
}

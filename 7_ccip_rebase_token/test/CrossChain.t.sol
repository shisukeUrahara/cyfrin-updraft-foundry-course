// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {IRebaseToken} from "../src/Interfaces/IRebaseToken.sol";
import {CCIPLocalSimulatorFork} from "chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";

contract CrossChainTest is Test {
    RebaseToken rebaseToken;
    RebaseTokenPool rebaseTokenPool;
    uint256 ethSepoliaFork;
    uint256 baseSepoliaFork;
    CCIPLocalSimulatorFork ccipLocalSimulatorFork;
    function setUp() public {
        rebaseToken = new RebaseToken();
        ethSepoliaFork = vm.createSelectFork("eth-sepolia");
        baseSepoliaFork = vm.createSelectFork("base-sepolia");
        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.setPersistentFork(address(ccipLocalSimulatorFork));
    }

    function testCrossChain() public {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
contract DSCEngineTest is Test {
    DeployDSC deployer;
    DSCEngine dscEngine;
    DecentralizedStableCoin dsc;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, dscEngine) = deployer.run();
    }

    /////////////////////////
    //// TEST PRICE FEEDS ////
    /////////////////////////
    function test_PriceFeedsAreSetInConstructor() public {
        address[] memory tokenAddresses = dscEngine.getAllowedTokens();
        // for each token address, get the price feeds and make sure they are not zero addresses
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            address priceFeedAddress = dscEngine.getPriceFeedForToken(
                tokenAddresses[i]
            );
            assertNotEq(priceFeedAddress, address(0));
        }
    }
}

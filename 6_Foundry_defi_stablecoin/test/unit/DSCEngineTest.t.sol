// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DSCEngine dscEngine;
    DecentralizedStableCoin dsc;
    HelperConfig.NetworkConfig config;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address wethAddress;
    address wbtcAddress;
    function setUp() external {
        deployer = new DeployDSC();
        (dsc, dscEngine, config) = deployer.run();
        ethUsdPriceFeed = config.priceFeedAddresses[0]; // ETH/USD
        btcUsdPriceFeed = config.priceFeedAddresses[1]; // BTC/USD
        wethAddress = config.tokenAddresses[0]; // WETH address
        wbtcAddress = config.tokenAddresses[1]; // WBTC
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

    // testing getUsdValue
    function test_getUsdValue() public {
        uint256 ethAmount = 1 ether;
        uint256 ethPrice = 2000;
        uint256 expectedUsd = ethAmount * ethPrice; // 2000e18
        uint256 actualUsd = dscEngine.getUsdValueOfToken(
            wethAddress,
            ethAmount
        );
        assertEq(actualUsd, expectedUsd);
    }
}

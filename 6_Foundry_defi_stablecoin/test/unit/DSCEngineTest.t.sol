// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
contract DSCEngineTest is Test {
    DeployDSC deployer;
    DSCEngine dscEngine;
    DecentralizedStableCoin dsc;
    HelperConfig.NetworkConfig config;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address wethAddress;
    address wbtcAddress;
    address USER = makeAddr("USER");
    uint256 constant AMOUNT_COLLATERAL = 10 ether;
    uint256 constant STARTING_BALANCE = 100 ether;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, dscEngine, config) = deployer.run();
        ethUsdPriceFeed = config.priceFeedAddresses[0]; // ETH/USD
        btcUsdPriceFeed = config.priceFeedAddresses[1]; // BTC/USD
        wethAddress = config.tokenAddresses[0]; // WETH address
        wbtcAddress = config.tokenAddresses[1]; // WBTC
        vm.deal(USER, STARTING_BALANCE);
        ERC20Mock(wethAddress).mint(USER, STARTING_BALANCE);
    }

    /////////////////////////
    //// TEST PRICE FEEDS ////
    /////////////////////////
    function test_PriceFeedsAreSetInConstructor() public view {
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
    function test_getUsdValue() public view {
        uint256 ethAmount = 1 ether;
        uint256 ethPrice = 2000;
        uint256 expectedUsd = ethAmount * ethPrice; // 2000e18
        uint256 actualUsd = dscEngine.getUsdValueOfToken(
            wethAddress,
            ethAmount
        );
        assertEq(actualUsd, expectedUsd);
    }

    /////////////////////////
    //// DEPOSIT COLLATERAL TESTS ////
    /////////////////////////
    function test_revertsWhenUserDepositsZeroCollateral() public {
        vm.startPrank(USER);
        ERC20Mock(wethAddress).approve(address(dscEngine), AMOUNT_COLLATERAL);
        vm.expectRevert(
            DSCEngine.DSCEngine__AmountMustBeGreaterThanZero.selector
        );
        dscEngine.depositCollateral(wethAddress, 0);
        vm.stopPrank();
    }
}

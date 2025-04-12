// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "../test/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address[] tokenAddresses;
        address[] priceFeedAddresses;
    }

    NetworkConfig private s_activeNetworkConfig;

    // Price Feed Constants
    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE = 2000e8;
    int256 public constant BTC_USD_PRICE = 1000e8;

    constructor() {
        if (block.chainid == 11155111) {
            s_activeNetworkConfig = getSepoliaEthConfig();
        } else {
            s_activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getActiveNetworkConfig()
        public
        view
        returns (NetworkConfig memory)
    {
        return s_activeNetworkConfig;
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        address[] memory tokenAddresses = new address[](2);
        address[] memory priceFeedAddresses = new address[](2);

        // Sepolia Addresses
        // todo: add the correct addresses later
        tokenAddresses[0] = 0x36e15B649a9D7cBf7bF44e41061F7AE53F58Afa5; // WETH
        tokenAddresses[1] = 0x36e15B649a9D7cBf7bF44e41061F7AE53F58Afa5; // WBTC

        priceFeedAddresses[0] = 0x36e15B649a9D7cBf7bF44e41061F7AE53F58Afa5; // ETH/USD
        priceFeedAddresses[1] = 0x36e15B649a9D7cBf7bF44e41061F7AE53F58Afa5; // BTC/USD

        return
            NetworkConfig({
                tokenAddresses: tokenAddresses,
                priceFeedAddresses: priceFeedAddresses
            });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // If we already have an active network config, return it
        if (s_activeNetworkConfig.tokenAddresses.length != 0) {
            return s_activeNetworkConfig;
        }

        address[] memory tokenAddresses = new address[](2);
        address[] memory priceFeedAddresses = new address[](2);

        vm.startBroadcast();
        // Deploy mocks
        MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(
            DECIMALS,
            ETH_USD_PRICE
        );
        MockV3Aggregator btcUsdPriceFeed = new MockV3Aggregator(
            DECIMALS,
            BTC_USD_PRICE
        );

        ERC20Mock weth = new ERC20Mock("WETH", "WETH", 1e27);
        ERC20Mock wbtc = new ERC20Mock("WBTC", "WBTC", 1e27);
        vm.stopBroadcast();

        tokenAddresses[0] = address(weth);
        tokenAddresses[1] = address(wbtc);
        priceFeedAddresses[0] = address(ethUsdPriceFeed);
        priceFeedAddresses[1] = address(btcUsdPriceFeed);

        return
            NetworkConfig({
                tokenAddresses: tokenAddresses,
                priceFeedAddresses: priceFeedAddresses
            });
    }
}

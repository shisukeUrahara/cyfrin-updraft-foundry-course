// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployDSC is Script {
    function run()
        external
        returns (
            DecentralizedStableCoin,
            DSCEngine,
            HelperConfig.NetworkConfig memory config
        )
    {
        // Get the network configuration
        HelperConfig helperConfig = new HelperConfig();
        config = helperConfig.getActiveNetworkConfig();

        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the DSC token
        DecentralizedStableCoin dsc = new DecentralizedStableCoin();

        // Deploy the DSC Engine with the configured token addresses and price feeds
        DSCEngine engine = new DSCEngine(
            address(dsc),
            config.tokenAddresses,
            config.priceFeedAddresses
        );

        vm.stopBroadcast();
        return (dsc, engine, config);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {RateLimiter} from "ccip/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";
import {TokenPool} from "ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";

contract ConfigurePool is Script {
    function run(
        address localPool,
        uint64 remoteChainSelector,
        address remoteToken,
        address remotePool,
        bool isOutboundRateLimited,
        uint128 outBoundRateLimitCapacity,
        uint128 outBoundRateLimitRate,
        bool isInboundRateLimited,
        uint128 inBoundRateLimitCapacity,
        uint128 inBoundRateLimitRate
    ) public {
        vm.startBroadcast();

        TokenPool.ChainUpdate[]
            memory chainsToAdd = new TokenPool.ChainUpdate[](1);
        chainsToAdd[0] = TokenPool.ChainUpdate({
            remoteChainSelector: remoteChainSelector,
            allowed: true,
            remotePoolAddress: abi.encode(remotePool),
            remoteTokenAddress: abi.encode(remoteToken),
            outboundRateLimiterConfig: RateLimiter.Config({
                isEnabled: isOutboundRateLimited,
                capacity: outBoundRateLimitCapacity,
                rate: outBoundRateLimitRate
            }),
            inboundRateLimiterConfig: RateLimiter.Config({
                isEnabled: isInboundRateLimited,
                capacity: inBoundRateLimitCapacity,
                rate: inBoundRateLimitRate
            })
        });
        TokenPool(localPool).applyChainUpdates(chainsToAdd);
        vm.stopBroadcast();
    }
}

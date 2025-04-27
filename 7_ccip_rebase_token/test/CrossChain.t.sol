// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {IRebaseToken} from "../src/Interfaces/IRebaseToken.sol";
import {CCIPLocalSimulatorFork, Register} from "chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";
import {Vault} from "../src/Vault.sol";
import {IERC20} from "ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {RegistryModuleOwnerCustom} from "ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from "ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {TokenPool} from "ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {RateLimiter} from "ccip/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";
contract CrossChainTest is Test {
    address owner = makeAddr("owner");
    RebaseToken rebaseToken;
    RebaseTokenPool rebaseTokenPool;
    uint256 ethSepoliaFork;
    uint256 baseSepoliaFork;
    CCIPLocalSimulatorFork ccipLocalSimulatorFork;
    RebaseToken ethSepoliaRebaseToken;
    RebaseToken baseSepoliaRebaseToken;
    RebaseTokenPool ethSepoliaRebaseTokenPool;
    RebaseTokenPool baseSepoliaRebaseTokenPool;
    Vault vault; // vault on source chain i.e eth sepolia
    Register.NetworkDetails ethSepoliaNetworkDetails;
    Register.NetworkDetails baseSepoliaNetworkDetails;

    function setUp() public {
        rebaseToken = new RebaseToken();
        ethSepoliaFork = vm.createSelectFork("eth-sepolia");
        baseSepoliaFork = vm.createSelectFork("base-sepolia");
        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();

        ethSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(
            block.chainid
        );
        baseSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(
            block.chainid
        );
        vm.makePersistent(address(ccipLocalSimulatorFork));

        // deploy and configure everything on eth sepolia chain
        vm.startPrank(owner);
        ethSepoliaRebaseToken = new RebaseToken();
        vault = new Vault(address(ethSepoliaRebaseToken));

        ethSepoliaRebaseTokenPool = new RebaseTokenPool(
            IERC20(address(ethSepoliaRebaseToken)),
            new address[](0),
            ethSepoliaNetworkDetails.rmnProxyAddress,
            ethSepoliaNetworkDetails.routerAddress
        );

        ethSepoliaRebaseToken.grantMintAndBurnRole(address(vault));
        ethSepoliaRebaseToken.grantMintAndBurnRole(
            address(ethSepoliaRebaseTokenPool)
        );
        RegistryModuleOwnerCustom(
            ethSepoliaNetworkDetails.registryModuleOwnerCustomAddress
        ).registerAdminViaOwner(address(ethSepoliaRebaseToken));
        TokenAdminRegistry(ethSepoliaNetworkDetails.tokenAdminRegistryAddress)
            .acceptAdminRole(address(ethSepoliaRebaseToken));

        TokenAdminRegistry(ethSepoliaNetworkDetails.tokenAdminRegistryAddress)
            .setPool(
                address(ethSepoliaRebaseToken),
                address(ethSepoliaRebaseTokenPool)
            );
        vm.stopPrank();

        // deploy and configure everything on base sepolia chain
        vm.selectFork(baseSepoliaFork);
        vm.startPrank(owner);
        baseSepoliaRebaseToken = new RebaseToken();
        baseSepoliaRebaseTokenPool = new RebaseTokenPool(
            IERC20(address(baseSepoliaRebaseToken)),
            new address[](0),
            baseSepoliaNetworkDetails.rmnProxyAddress,
            baseSepoliaNetworkDetails.routerAddress
        );
        baseSepoliaRebaseToken.grantMintAndBurnRole(
            address(baseSepoliaRebaseTokenPool)
        );
        RegistryModuleOwnerCustom(
            baseSepoliaNetworkDetails.registryModuleOwnerCustomAddress
        ).registerAdminViaOwner(address(baseSepoliaRebaseToken));
        TokenAdminRegistry(baseSepoliaNetworkDetails.tokenAdminRegistryAddress)
            .acceptAdminRole(address(baseSepoliaRebaseToken));
        TokenAdminRegistry(baseSepoliaNetworkDetails.tokenAdminRegistryAddress)
            .setPool(
                address(baseSepoliaRebaseToken),
                address(baseSepoliaRebaseTokenPool)
            );
        configureTokenPool(
            ethSepoliaFork,
            address(ethSepoliaRebaseTokenPool),
            baseSepoliaNetworkDetails.chainSelector,
            true,
            address(baseSepoliaRebaseTokenPool),
            address(baseSepoliaRebaseToken)
        );
        vm.stopPrank();
    }

    function configureTokenPool(
        uint256 fork,
        address localPool,
        uint64 remoteChainSelector,
        bool enableChain,
        address remotePoolAddress,
        address remoteTokenAddress
    ) public {
        vm.selectFork(fork);
        vm.startPrank(owner);
        TokenPool.ChainUpdate[]
            memory chainsToAdd = new TokenPool.ChainUpdate[](1);
        chainsToAdd[0] = TokenPool.ChainUpdate({
            remoteChainSelector: remoteChainSelector,
            allowed: enableChain,
            remotePoolAddress: abi.encode(remotePoolAddress),
            remoteTokenAddress: abi.encode(remoteTokenAddress),
            outboundRateLimiterConfig: RateLimiter.Config({
                isEnabled: false,
                capacity: 0,
                rate: 0
            }),
            inboundRateLimiterConfig: RateLimiter.Config({
                isEnabled: false,
                capacity: 0,
                rate: 0
            })
        });
        TokenPool(localPool).applyChainUpdates(chainsToAdd);

        vm.stopPrank();
    }

    function testCrossChain() public {}
}

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
import {Client} from "ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";

contract CrossChainTest is Test {
    address owner = makeAddr("owner");
    address user = makeAddr("user");
    uint256 SEND_VALUE = 1e5;
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
        uint256 ethSepoliaChainId = 11155111;
        uint256 baseSepoliaChainId = 84532;
        ethSepoliaFork = vm.createSelectFork("eth-sepolia");
        baseSepoliaFork = vm.createFork("base-sepolia");
        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();

        ethSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(
            ethSepoliaChainId
        );
        baseSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(
            baseSepoliaChainId
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

        // Configure the destination pool to allow the source chain
        configureTokenPool(
            baseSepoliaFork,
            address(baseSepoliaRebaseTokenPool),
            ethSepoliaNetworkDetails.chainSelector,
            true,
            address(ethSepoliaRebaseTokenPool),
            address(ethSepoliaRebaseToken)
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

    function bridgeToken(
        uint256 _amountToBridge,
        uint256 localFork,
        uint256 remoteFork,
        Register.NetworkDetails memory localNetworkDetails,
        Register.NetworkDetails memory remoteNetworkDetails,
        address localToken,
        address remoteToken
    ) public {
        vm.selectFork(localFork);

        // doing stuff on local fork
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: localToken,
            amount: _amountToBridge
        });
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(user),
            data: "",
            tokenAmounts: tokenAmounts,
            feeToken: localNetworkDetails.linkAddress,
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({
                    gasLimit: 1000000 // we don't want a custom gas limit
                })
            )
        });

        uint256 fee = IRouterClient(localNetworkDetails.routerAddress).getFee(
            remoteNetworkDetails.chainSelector,
            message
        );

        console.log("link fee is , ", fee);

        // need link for fees , but doesnot work between startPrank and stopPrank
        uint256 userLinkBeforeFaucetRequestBalance = IERC20(
            localNetworkDetails.linkAddress
        ).balanceOf(user);
        console.log(
            "user link before faucet request balance is , ",
            userLinkBeforeFaucetRequestBalance
        );
        ccipLocalSimulatorFork.requestLinkFromFaucet(user, fee);

        uint256 userLinkAfterFaucetRequestBalance = IERC20(
            localNetworkDetails.linkAddress
        ).balanceOf(user);
        console.log(
            "user link after faucet request balance is , ",
            userLinkAfterFaucetRequestBalance
        );
        // ccipLocalSimulatorFork.(user, fee);

        vm.prank(user);
        IERC20(localNetworkDetails.linkAddress).approve(
            localNetworkDetails.routerAddress,
            fee
        );

        console.log("**@ here 1");

        vm.startPrank(user);
        IERC20(localToken).approve(
            localNetworkDetails.routerAddress,
            _amountToBridge
        );

        console.log("**@ here 2");

        uint256 beforeBalance = IERC20(localToken).balanceOf(user);
        // vm.prank(user);
        IRouterClient(localNetworkDetails.routerAddress).ccipSend(
            remoteNetworkDetails.chainSelector,
            message
        );

        vm.stopPrank();

        console.log("**@ here 3");
        uint256 afterBalance = IERC20(localToken).balanceOf(user);
        assertEq(afterBalance, beforeBalance - _amountToBridge);
        uint256 localUserInterestRate = IRebaseToken(localToken)
            .getUserInterestRate(user);

        console.log("**@ here 4");

        // doing stuff on remote fork
        vm.selectFork(remoteFork);
        vm.warp(block.timestamp + 20 minutes);
        uint256 remoteBeforeBalance = IERC20(remoteToken).balanceOf(user);
        console.log("**@ here 5");
        // vm.prank(user);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(remoteFork);
        uint256 remoteAfterBalance = IERC20(remoteToken).balanceOf(user);
        assertEq(remoteAfterBalance - remoteBeforeBalance, _amountToBridge);
        uint256 RemoteUserInterestRate = IRebaseToken(remoteToken)
            .getUserInterestRate(user);

        console.log("**@ here 6");
        assertEq(RemoteUserInterestRate, localUserInterestRate);
    }

    function testBridgeAllTokens() public {
        vm.selectFork(ethSepoliaFork);

        vm.deal(user, SEND_VALUE);
        vm.startPrank(user);
        Vault(payable(address(vault))).deposit{value: SEND_VALUE}();
        assertEq(
            IERC20(address(ethSepoliaRebaseToken)).balanceOf(user),
            SEND_VALUE
        );

        vm.stopPrank();

        bridgeToken(
            SEND_VALUE,
            ethSepoliaFork,
            baseSepoliaFork,
            ethSepoliaNetworkDetails,
            baseSepoliaNetworkDetails,
            address(ethSepoliaRebaseToken),
            address(baseSepoliaRebaseToken)
        );
    }
}

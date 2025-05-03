// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {IRouterClient} from "ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

contract BridgeTokens is Script {
    function run(
        address ccipRouterAddress,
        uint64 destinationChainSelector,
        address receiverAddress,
        address tokenToSendAddress,
        uint256 amountToBridge,
        address linkTokenAddress
    ) public {
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: tokenToSendAddress,
            amount: amountToBridge
        });
        vm.startBroadcast();
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiverAddress),
            data: "",
            tokenAmounts: tokenAmounts,
            feeToken: linkTokenAddress,
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({
                    gasLimit: 0 // we don't want a custom gas limit
                })
            )
        });

        uint256 ccipFees = IRouterClient(ccipRouterAddress).getFee(
            destinationChainSelector,
            message
        );

        IERC20(linkTokenAddress).approve(ccipRouterAddress, ccipFees);

        IERC20(tokenToSendAddress).approve(ccipRouterAddress, amountToBridge);
        IRouterClient(ccipRouterAddress).ccipSend{value: ccipFees}(
            destinationChainSelector,
            message
        );

        vm.stopBroadcast();
    }
}

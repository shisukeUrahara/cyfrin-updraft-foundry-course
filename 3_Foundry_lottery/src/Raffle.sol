// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title Raffle Contract
 * @author @ShisukeUrahara
 * @notice This contract is a simple raffle contract that allows users to participate in a raffle by purchasing tickets
 * @dev Implements chainlink VRF to select a random winner from a list of participants to win the lottery
 */
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    // errors
    error Raffle__NotEnoughEthEntered();
    error Raffle__NotEnoughTimeHasPassed();
    // State variables
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval; // duration of the raffle in seconds
    address payable[] private s_players;
    uint256 private s_lastTimestamp;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // events
    event RaffleEntered(address indexed player);

    // a constructor that initializes the entrance fee
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gaslane, // keyHash for the gaslane
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimestamp = block.timestamp;
        i_keyHash = gaslane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    // a function to enter the raffle
    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthEntered();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    // a function to pick a random winner
    function pickWinner() external {
        if ((block.timestamp - s_lastTimestamp) < i_interval) {
            revert Raffle__NotEnoughTimeHasPassed();
        }

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
        // Will revert if subscription is not set and funded.
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    /**
     * @dev This is the function that Chainlink VRF node
     * calls to send the money to the random winner.
     */
    function fulfillRandomWords(
        uint256,
        /* requestId */ uint256[] calldata randomWords
    ) internal override {
        // // s_players size 10
        // // randomNumber 202
        // // 202 % 10 ? what's doesn't divide evenly into 202?
        // // 20 * 10 = 200
        // // 2
        // // 202 % 10 = 2
        // uint256 indexOfWinner = randomWords[0] % s_players.length;
        // address payable recentWinner = s_players[indexOfWinner];
        // s_recentWinner = recentWinner;
        // s_players = new address payable[](0);
        // s_raffleState = RaffleState.OPEN;
        // s_lastTimeStamp = block.timestamp;
        // emit WinnerPicked(recentWinner);
        // (bool success, ) = recentWinner.call{value: address(this).balance}("");
        // // require(success, "Transfer failed");
        // if (!success) {
        //     revert Raffle__TransferFailed();
        // }
    }

    // a function to get the entrance fee
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    // a function to get the interval
    function getInterval() public view returns (uint256) {
        return i_interval;
    }
}

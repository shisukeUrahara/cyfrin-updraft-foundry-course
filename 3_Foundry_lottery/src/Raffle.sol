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

contract Raffle {
    // errors
    error Raffle__NotEnoughEthEntered();

    // State variables
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;

    // events
    event RaffleEntered(address indexed player);

    // a constructor that initializes the entrance fee
    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    // a function to enter the raffle
    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthEntered();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    // a function to pick a random winner
    function pickWinner() external {}

    // a function to get the entrance fee
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}

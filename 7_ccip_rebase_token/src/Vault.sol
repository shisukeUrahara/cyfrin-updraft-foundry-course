// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
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
contract Vault {
    // ERRORS
    error Vault__NotEnoughBalance();
    // state variables
    address private immutable i_rebaseToken;

    // events

    constructor(address _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }

    function getRebaseTokenAddress() external view returns (address) {
        return i_rebaseToken;
    }
}

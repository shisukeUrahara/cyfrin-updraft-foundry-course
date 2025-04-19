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

import {IRebaseToken} from "./Interfaces/IRebaseToken.sol";
contract Vault {
    // ERRORS
    error Vault__CannotDepositZero();
    // state variables
    address private immutable i_rebaseToken;

    // events
    event Deposit(address indexed user, uint256 amount);
    constructor(address _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }

    receive() external payable {}

    function deposit() external payable {
        if (msg.value == 0) {
            revert Vault__CannotDepositZero();
        }
        IRebaseToken(i_rebaseToken).mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function getRebaseTokenAddress() external view returns (address) {
        return i_rebaseToken;
    }
}

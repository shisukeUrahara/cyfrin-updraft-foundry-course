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
    error Vault__RedeemFailed();
    // state variables
    address private immutable i_rebaseToken;
    // events
    event Deposit(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);
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

    function redeem(uint256 _amount) external {
        // If max uint256 is passed as amount, we interpret this as a request to redeem
        // the user's entire balance. This is a common pattern that allows burning all
        // tokens without needing to query the balance first in a separate call.
        if (_amount == type(uint256).max) {
            _amount = IRebaseToken(i_rebaseToken).balanceOf(msg.sender);
        }
        IRebaseToken(i_rebaseToken).burn(msg.sender, _amount);
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert Vault__RedeemFailed();
        }
        emit Redeem(msg.sender, _amount);
    }

    function getRebaseTokenAddress() external view returns (address) {
        return i_rebaseToken;
    }
}

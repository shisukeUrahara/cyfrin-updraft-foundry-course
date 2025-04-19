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

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
 * @title RebaseToken
 * @author @ShisukeUrahara
 * @notice A token that incentivizes holding by rebasing the token supply
 * @notice The interrest rate can only be decreased, not increased
 */
contract RebaseToken is ERC20 {
    // errors
    error RebaseToken__CannotIncreaseInterestRate(
        uint256 oldInterestRate,
        uint256 newInterestRate
    );

    // state variables
    uint256 private s_interestRate = 5e10; // 1e18 ~1%

    // events
    event InterestRateSet(uint256 newInterestRate);

    // constructor
    constructor() ERC20("RebaseToken", "RBT") {
        _mint(msg.sender, 1000000000000000000000000);
    }

    function setInterestRate(uint256 newInterestRate) external {
        if (newInterestRate > s_interestRate) {
            revert RebaseToken__CannotIncreaseInterestRate(
                s_interestRate,
                newInterestRate
            );
        }
        s_interestRate = newInterestRate;
        emit InterestRateSet(newInterestRate);
    }
}

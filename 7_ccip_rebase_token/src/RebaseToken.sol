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
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimestamp;
    uint256 private constant PRECISION_FACTOR = 1e18;

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
    /**
     * @notice Mints new tokens to the specified address and updates their interest rate
     * @param _to The address to mint tokens to
     * @param _amount The amount of tokens to mint
     * @dev This function also mints any accrued interest before the new tokens are minted
     * @dev The caller's interest rate is updated to the current global interest rate
     */

    function mint(address _to, uint256 _amount) external {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);
    }

    /**
     * @notice Returns the current balance of a user including accrued interest
     * @param _user The address to check the balance of
     * @return The user's balance with accumulated interest
     * @dev This overrides the standard ERC20 balanceOf to include interest calculations
     * @dev The balance returned includes both the base balance and any pending interest
     */
    function balanceOf(address _user) public view override returns (uint256) {
        // 1.) what we need is principle + simple interest
        // simple interest = principle * interest rate * time
        // so balance = principle * (1 + interest rate * time)
        // so _calculateUserAccumulatedInterestSinceLastUpdate() is the(1+ interest rate * time)
        return
            (super.balanceOf(_user) *
                _calculateUserAccumulatedInterestSinceLastUpdate(_user)) /
            PRECISION_FACTOR;
    }

    function _calculateUserAccumulatedInterestSinceLastUpdate(
        address _user
    ) internal view returns (uint256) {
        // we need to calculate the interest rate since the last update
        // its simple linear interest
        // check comments in balanceOf()
        // for this function, we need to return (1+ interest rate * time)
        // eg
        uint256 timeElapsed = block.timestamp -
            s_userLastUpdatedTimestamp[_user];
        uint256 userInterestRate = s_userInterestRate[_user];

        return PRECISION_FACTOR + (userInterestRate * timeElapsed);
    }

    /*
     * @notice Calculates the accumulated interest factor for a user since their last update
     * @param _user The address of the user to calculate interest for
     * @return The accumulated interest factor scaled by PRECISION_FACTOR
     * @dev Returns (1 + interest_rate * time_elapsed) using simple linear interest
     * @dev The returned value is used as a multiplier to calculate total balance with interest
     */
    function _mintAccruedInterest(address _user) internal {
        // 1. Calculate the accrued interest
        uint256 previousPrincipleBalance = super.balanceOf(_user);
        uint256 currentBalance = balanceOf(_user);
        // accrued interest since the last update timestamp
        uint256 accruedInterest = currentBalance - previousPrincipleBalance;
        // update the last updated timestamp
        s_userLastUpdatedTimestamp[_user] = block.timestamp;
        //  Mint the accrued interest
        _mint(_user, accruedInterest);
    }

    function burn(address _from, uint256 _amount) external {
        // If max uint256 is passed as amount, we interpret this as a request to burn
        // the user's entire balance. This is a common pattern that allows burning all
        // tokens without needing to query the balance first in a separate call.
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_from);
        }
        _mintAccruedInterest(_from);
        _burn(_from, _amount);
    }

    function transfer(
        address _to,
        uint256 _amount
    ) public override returns (bool) {
        // We need to mint any accrued interest for both sender and receiver before the transfer
        // This ensures interest is properly credited before modifying balances
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_to);

        // If max uint256 is passed, interpret as request to transfer entire balance
        // This is a convenience feature to avoid separate balanceOf call
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }

        // If the recipient has no balance yet, they inherit the sender's interest rate
        if (balanceOf(_to) == 0) {
            s_userInterestRate[_to] = s_userInterestRate[msg.sender];
        }
        return super.transfer(_to, _amount);
    }

    function getInterestRate(address _user) external view returns (uint256) {
        return s_userInterestRate[_user];
    }
}

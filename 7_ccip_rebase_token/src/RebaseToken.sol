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
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
/**
 * @title RebaseToken
 * @author @ShisukeUrahara
 * @notice A token that incentivizes holding by rebasing the token supply
 * @notice The interrest rate can only be decreased, not increased
 */
contract RebaseToken is ERC20, Ownable, AccessControl {
    // errors
    error RebaseToken__CannotIncreaseInterestRate(
        uint256 oldInterestRate,
        uint256 newInterestRate
    );

    // state variables
    uint256 private constant PRECISION_FACTOR = 1e27;
    bytes32 public constant MINT_AND_BURN_ROLE =
        keccak256("MINT_AND_BURN_ROLE");
    uint256 private s_interestRate = (5 * PRECISION_FACTOR) / 1e8; // 1e18 ~1%
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimestamp;

    // events
    event InterestRateSet(uint256 newInterestRate);

    // constructor
    constructor() ERC20("RebaseToken", "RBT") Ownable(msg.sender) {
        _mint(msg.sender, 1000000000000000000000000);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function grantMintAndBurnRole(address _to) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, _to);
    }

    /**
     * @notice Updates the global interest rate for the token
     * @param newInterestRate The new interest rate to set
     * @dev The new interest rate must be less than or equal to the current rate
     * @dev Interest rates are scaled by 1e18 (PRECISION_FACTOR)
     */
    function setInterestRate(uint256 newInterestRate) external onlyOwner {
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

    function mint(
        address _to,
        uint256 _amount
    ) external onlyRole(MINT_AND_BURN_ROLE) {
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

    /**
     * @notice Burns tokens from a specified address
     * @param _from The address to burn tokens from
     * @param _amount The amount of tokens to burn, or max uint256 to burn entire balance
     * @dev If _amount is max uint256, burns the entire balance including accrued interest
     * @dev Mints any accrued interest before burning to ensure accurate burning amount
     */
    function burn(
        address _from,
        uint256 _amount
    ) external onlyRole(MINT_AND_BURN_ROLE) {
        // If max uint256 is passed as amount, we interpret this as a request to burn
        // the user's entire balance. This is a common pattern that allows burning all
        // tokens without needing to query the balance first in a separate call.
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_from);
        }
        _mintAccruedInterest(_from);
        _burn(_from, _amount);
    }

    /**
     * @notice Transfers tokens to another address
     * @param _to The address to transfer tokens to
     * @param _amount The amount of tokens to transfer, or max uint256 to transfer entire balance
     * @return bool Returns true if the transfer was successful
     * @dev Mints accrued interest for both sender and receiver before transfer
     * @dev If recipient has no balance, they inherit sender's interest rate
     * @dev Overrides ERC20 transfer to handle interest accrual
     */
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

    /**
     * @notice Transfers tokens from one address to another using allowance
     * @param _from The address to transfer tokens from
     * @param _to The address to transfer tokens to
     * @param _amount The amount of tokens to transfer, or max uint256 to transfer entire balance
     * @return bool Returns true if the transfer was successful
     * @dev Mints accrued interest for both sender and receiver before transfer
     * @dev If recipient has no balance, they inherit sender's interest rate
     * @dev Overrides ERC20 transferFrom to handle interest accrual
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public override returns (bool) {
        _mintAccruedInterest(_from);
        _mintAccruedInterest(_to);

        if (_amount == type(uint256).max) {
            _amount = balanceOf(_from);
        }

        if (balanceOf(_to) == 0) {
            s_userInterestRate[_to] = s_userInterestRate[_from];
        }

        return super.transferFrom(_from, _to, _amount);
    }

    /**
     * @notice Gets the current interest rate for a specific user
     * @param _user The address to get the interest rate for
     * @return The user's current interest rate
     */
    function getInterestRate(address _user) external view returns (uint256) {
        return s_userInterestRate[_user];
    }

    /**
     * @notice Gets the principle balance of a specific user
     * @param _user The address to get the principle balance for
     * @return The user's principle balance
     */
    function principleBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }

    /**
     * @notice Gets the current interest rate for a specific user
     * @param _user The address to get the interest rate for
     * @return The user's current interest rate
     * @dev This is a duplicate of getInterestRate(address) and should be deprecated
     */
    function getUserInterestRate(
        address _user
    ) external view returns (uint256) {
        return s_userInterestRate[_user];
    }

    /**
     * @notice Gets the current global interest rate for the token
     * @return The current global interest rate scaled by PRECISION_FACTOR
     * @dev Interest rates are scaled by 1e18 (PRECISION_FACTOR)
     */
    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }
}

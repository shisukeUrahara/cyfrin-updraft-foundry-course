// SPDX-License-Identifier: MIT

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

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

pragma solidity ^0.8.19;
import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
/*
 *@title DecentralizedStableCoin
 *@author ShisukeUrahara
 * Collateral: Exogenous (WETH & WBTC)
 * Minting: Algorithmic
 * Relative stability: Pegged to the US Dollar
 *@dev This contract is a simple ERC20 contract that allows users to mint and burn the coin
 */
contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    //  custom errors
    error DecentralizedStableCoin__AmountMustBeGreaterThanZero();
    error DecentralizedStableCoin__BurnAmountExceedsBalance();
    error DecentralizedStableCoin__NotEnoughCollateral();
    error DecentralizedStableCoin__MintExceedsBalance();
    error DecentralizedStableCoin__MustBeMoreThanZero();
    error DecentralizedStableCoin__MintToZeroAddress();
    constructor() ERC20("DecentralizedStableCoin", "DSC") Ownable(msg.sender) {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DecentralizedStableCoin__AmountMustBeGreaterThanZero();
        }
        if (_amount > balance) {
            revert DecentralizedStableCoin__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    function mint(
        address _to,
        uint256 _amount
    ) public onlyOwner returns (bool) {
        if (_amount <= 0) {
            revert DecentralizedStableCoin__AmountMustBeGreaterThanZero();
        }
        if (_to == address(0)) {
            revert DecentralizedStableCoin__MintToZeroAddress();
        }
        _mint(_to, _amount);
        return true;
    }
}

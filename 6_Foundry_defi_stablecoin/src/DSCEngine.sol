// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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

/**
 * @title DSCEngine
 * @author Shisuke Urahara
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg.
 * This stablecoin has the properties:
 * - Exogenous Collateral
 * - Dollar Pegged
 * - Algoritmically Stable
 *
 * It is similar to DAI if DAI had no governance, no fees, and was only backed by WETH and WBTC.
 */

/*
 * @notice This contract is the core of the DSC System. It handles all the logic for mining and redeeming DSC, as well as depositing & withdrawing collateral.
 * @notice This contract is VERY loosely based on the MakerDAO DSS (DAI) system.
 */

contract DSCEngine {
    function depositCollateralAndMintDSC(
        address _token,
        uint256 _amount,
        uint256 _mintAmount
    ) public {}

    function depsitCollateral() external {}

    function redeemCollateral(address _token, uint256 _amount) public {}

    function redeemCollateralForDSC(
        address _token,
        uint256 _amount,
        uint256 _redeemAmount
    ) public {}

    function mintDSC(uint256 _amount) public {}

    function burnDSC(uint256 _amount) public {}

    function liquidate() public {}

    function getHealthFactor() public view returns (uint256) {}
}

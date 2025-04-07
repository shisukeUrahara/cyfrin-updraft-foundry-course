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

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DSCEngine is ReentrancyGuard {
    // Errors
    ///////
    error DSCEngine__TokenNotAllowed();
    error DSCEngine__CollateralMustBeAllowedToken();
    error DSCEngine__MintExceedsBalance();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__AmountMustBeGreaterThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesLengthsMustBeTheSame();
    error DSCEngine__ZeroAddress();
    error DSCEngine__TransferFailed();

    //////////////
    // State Variables //
    //////////////
    mapping(address _token => address _priceFeed) private s_allowedTokens;
    mapping(address _user => mapping(address _token => uint256 _amount))
        private s_collateralDeposited;
    DecentralizedStableCoin private immutable i_dsc;

    /////////////
    // Events //
    ////////////
    event CollateralDeposited(
        address indexed user,
        address indexed token,
        uint256 amount
    );

    //////////////
    // Modifiers //
    //////////////
    modifier moreThanZero(uint256 _amount) {
        if (_amount <= 0) {
            revert DSCEngine__AmountMustBeGreaterThanZero();
        }
        _;
    }

    modifier isAllowedToken(address _token) {
        if (s_allowedTokens[_token] == address(0)) {
            revert DSCEngine__TokenNotAllowed();
        }
        _;
    }

    //////////////
    // Functions //
    //////////////

    constructor(
        address[] memory _allowedTokens,
        address[] memory _priceFeeds,
        address _dsc
    ) {
        if (_dsc == address(0)) {
            revert DSCEngine__ZeroAddress();
        }
        if (_allowedTokens.length != _priceFeeds.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesLengthsMustBeTheSame();
        }
        for (uint256 i = 0; i < _allowedTokens.length; i++) {
            s_allowedTokens[_allowedTokens[i]] = _priceFeeds[i];
        }
        i_dsc = DecentralizedStableCoin(_dsc);
    }

    /////////////////////////
    // External Functions //
    ////////////////////////
    function depositCollateralAndMintDSC(
        address _token,
        uint256 _amount,
        uint256 _mintAmount
    ) public {}

    /* 
    @notice: Allow users to deposit collateral and mint DSC
    @param _token: The address of the collateral token
    @param _amount: The amount of collateral to deposit
    */
    function depsitCollateral(
        address _collateral,
        uint256 _amount
    ) external moreThanZero(_amount) isAllowedToken(_collateral) nonReentrant {
        s_collateralDeposited[msg.sender][_collateral] += _amount;
        emit CollateralDeposited(msg.sender, _collateral, _amount);
        bool success = IERC20(_collateral).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

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

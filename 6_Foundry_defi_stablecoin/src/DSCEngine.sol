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
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

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
    mapping(address _user => uint256 _amount) private s_DSCMinted;
    address[] private s_collateralTokens;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;

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
            s_collateralTokens.push(_allowedTokens[i]);
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

    // @notice follows CEI (Checks, Effects, Interactions)
    // @dev Explain to a developer any extra details
    // @param _amount: The amount of DSC to mint
    // @notice user must have more collateral than the amount of DSC they want to mint
    // @inheritdoc	Copies all missing tags from the base function (must be followed by the contract name)
    function mintDSC(
        uint256 _amount
    ) external moreThanZero(_amount) nonReentrant {
        // Check if the user has enough collateral
        // Get the amount of collateral
        // Burn the DSC
        // Mint the DSC
        s_DSCMinted[msg.sender] += _amount;
        // if they don't have enough collateral, revert
        revertIfHealthFactorIsBroken(msg.sender);
    }
    function burnDSC(uint256 _amount) public {}

    function liquidate() public {}

    function getHealthFactor() public view returns (uint256) {}

    /////////////////////////////////////////
    // Private and internal view Functions //
    /////////////////////////////////////////

    /*
    @notice: Internal view function to get the USD value of a collateral
    @param _token: The address of the collateral token
    @return: The USD value of the collateral
    */
    function getUsdValueOfCollateral(
        address _token
    ) internal view returns (uint256) {
        // get the price of the token from the price feed
        // get the amount of collateral from the user
        // return the price * the amount of collateral
        return 0;
    }

    /* 
    @notice: Internal view function to get the amount of collateral and DSC minted by a user
    @param user: The address of the user to get the information for
    @return: The amount of collateral and DSC minted by the user
    */
    function _getAccountInformation(
        address user
    )
        internal
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_DSCMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
        return (totalDscMinted, collateralValueInUsd);
    }

    /*
     * @notice: Internal view function to calculate the health factor of a user
     * @param user: The address of the user to calculate the health factor for
     * @return: The health factor of the user , if user gets below 1, they can be liquidated
     */
    function _healthFactor(address user) internal view returns (uint256) {
        // get the amount of collateral
        // get the amount of DSC minted
        // calculate the health factor
        (uint256 collateralAmount, uint256 dscMinted) = _getAccountInformation(
            user
        );
        return 0;
    }

    function revertIfHealthFactorIsBroken(address _user) internal view {
        // get the health factor
        // if the health factor is broken, revert
    }

    /////////////////////////////////////////
    // Public  and External  view Functions //
    /////////////////////////////////////////
    function getAccountCollateralValue(
        address _user
    ) public view returns (uint256 totalCollateralValueInUsd) {
        // loop through all the collateral tokens
        // get the price of the token from the price feed
        // get the total amount of collateral value for given user and return it
        // return the price * the amount of collateral
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[_user][token];
            totalCollateralValueInUsd += getUsdValueOfCollateral(token, amount);
        }
        return totalCollateralValueInUsd;
    }

    function getUsdValueOfCollateral(
        address _token,
        uint256 _amount
    ) public view returns (uint256) {
        // get the price of the token from the price feed
        // get the amount of collateral from the user
        // return the price * the amount of collateral
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            s_allowedTokens[_token]
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return
            (uint256(price) * ADDITIONAL_FEED_PRECISION * _amount) / PRECISION;
    }
}

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
    error DSCEngine__HealthFactorIsBroken(uint256 healthFactor);
    error DSCEngine__MintFailed();
    error DSCEngine__RedeemCollateralFailed();
    error DSCEngine__BurnFailed();
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
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // 50%
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1;
    /////////////
    // Events //
    ////////////
    event CollateralDeposited(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    event CollateralRedeemed(
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
        address _dsc,
        address[] memory _allowedTokens,
        address[] memory _priceFeeds
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

    // @notice: Allow users to deposit collateral and mint DSC
    // @param _token: The address of the collateral token
    // @param _amount: The amount of collateral to deposit
    // @param _mintAmount: The amount of DSC to mint
    // @dev: This function is a convenience function that deposits collateral and mints DSC in one step
    function depositCollateralAndMintDSC(
        address _token,
        uint256 _amount,
        uint256 _mintAmount
    ) public {
        depositCollateral(_token, _amount);
        mintDSC(_mintAmount);
    }

    /* 
    @notice: Allow users to deposit collateral and mint DSC
    @param _token: The address of the collateral token
    @param _amount: The amount of collateral to deposit
    */
    function depositCollateral(
        address _collateral,
        uint256 _amount
    ) public moreThanZero(_amount) isAllowedToken(_collateral) nonReentrant {
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

    // @notice: Allow users to redeem collateral
    // IN order to redeem collateral, the user must have enough collateral deposited
    // and the health factor must be greater than 1 after collateral pull
    // @param _token: The address of the collateral token
    // @param _amount: The amount of collateral to redeem
    // @dev: This function is a convenience function that redeems collateral and burns DSC in one step

    function redeemCollateral(
        address _token,
        uint256 _amount
    ) public moreThanZero(_amount) isAllowedToken(_token) nonReentrant {
        s_collateralDeposited[msg.sender][_token] -= _amount;
        emit CollateralRedeemed(msg.sender, _token, _amount);

        bool success = IERC20(_token).transfer(msg.sender, _amount);
        if (!success) {
            revert DSCEngine__RedeemCollateralFailed();
        }
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    /* 
@notice: Allow users to redeem collateral for DSC
@param _token: The address of the collateral token
@param _amount: The amount of collateral to redeem
@param _redeemAmount: The amount of DSC to redeem
@dev: This function is a convenience function that burns DSC and redeems collateral in one step
*/
    function redeemCollateralForDSC(
        address _token,
        uint256 _amount,
        uint256 _redeemAmount
    ) public {
        burnDSC(_redeemAmount);
        redeemCollateral(_token, _amount);
    }

    // @notice follows CEI (Checks, Effects, Interactions)
    // @dev Explain to a developer any extra details
    // @param _amount: The amount of DSC to mint
    // @notice user must have more collateral than the amount of DSC they want to mint
    // @inheritdoc	Copies all missing tags from the base function (must be followed by the contract name)
    function mintDSC(
        uint256 _amount
    ) public moreThanZero(_amount) nonReentrant {
        // Check if the user has enough collateral
        // Get the amount of collateral
        // Burn the DSC
        // Mint the DSC
        s_DSCMinted[msg.sender] += _amount;
        // if they don't have enough collateral, revert
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, _amount);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }
    function burnDSC(
        uint256 _amount
    ) public moreThanZero(_amount) nonReentrant {
        // burn the DSC
        // revert if the user has no DSC to burn
        // update the amount of DSC minted
        // update the health factor
        // revert if the health factor is broken
        // burn the DSC
        s_DSCMinted[msg.sender] -= _amount;
        bool success = i_dsc.transferFrom(msg.sender, address(this), _amount);
        // bool success = i_dsc.burn(msg.sender, _amount);
        if (!success) {
            revert DSCEngine__BurnFailed();
        }
        i_dsc.burn(_amount);
        _revertIfHealthFactorIsBroken(msg.sender); // MOST PROBABLY NOT NEEDED
    }

    function liquidate() public {}

    function getHealthFactor() public view returns (uint256) {}

    /////////////////////////////////////////
    // Private and internal view Functions //
    /////////////////////////////////////////

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
        (
            uint256 dscMinted,
            uint256 collateralValueInUsd
        ) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd *
            LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;

        return (collateralAdjustedForThreshold * PRECISION) / dscMinted;
    }

    function _revertIfHealthFactorIsBroken(address _user) internal view {
        // get the health factor
        // if the health factor is broken, revert
        uint256 healthFactor = _healthFactor(_user);
        if (healthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorIsBroken(healthFactor);
        }
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
            totalCollateralValueInUsd += getUsdValueOfToken(token, amount);
        }
        return totalCollateralValueInUsd;
    }

    function getUsdValueOfToken(
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

    function getAllowedTokens() public view returns (address[] memory) {
        return s_collateralTokens;
    }

    function getPriceFeedForToken(
        address _token
    ) public view returns (address) {
        return s_allowedTokens[_token];
    }
}

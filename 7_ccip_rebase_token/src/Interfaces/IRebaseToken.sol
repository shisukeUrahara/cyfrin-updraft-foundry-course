// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IRebaseToken is IERC20 {
    function mint(address to, uint256 amount, uint256 interestRate) external;
    function burn(address from, uint256 amount) external;
    function getInterestRate() external view returns (uint256);
    function getUserInterestRate(address user) external view returns (uint256);
    function grantMintAndBurnRole(address user) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/Interfaces/IRebaseToken.sol";

contract RebaseTokenTest is Test {
    RebaseToken rebaseToken;
    Vault vault;
    address public owner = makeAddr("owner");
    address public user = makeAddr("user");
    address public user2 = makeAddr("user2");
    function setUp() public {
        vm.startPrank(owner);
        rebaseToken = new RebaseToken();
        vault = new Vault(address(rebaseToken));
        rebaseToken.grantRole(rebaseToken.MINT_AND_BURN_ROLE(), address(vault));
        // add some funds to the vault
        // vm.deal(address(vault), 100 ether);
        vm.stopPrank();
    }

    function addRewardsToVault(uint256 amount) public {
        // send some rewards to the vault using the receive function
        payable(address(vault)).call{value: amount}("");
    }

    // a test case to test name
    function testName() public view {
        assertEq(rebaseToken.name(), "RebaseToken");
    }

    // a test case to test symbol
    function testSymbol() public view {
        assertEq(rebaseToken.symbol(), "RBT");
    }

    // this is a fuzz test with a fuzzed deposit amount
    function testDepositLinear(uint256 _depositAmount) public {
        vm.startPrank(user);

        // we want to run only the case where the deposit amount is greater than 1e5
        // vm.assume(_depositAmount > 1e5);

        //  this is when we manually adjust the deposit amount to be within a range for the fuzz tests
        _depositAmount = bound(_depositAmount, 1e5, type(uint96).max);
        vm.deal(user, _depositAmount);
        vault.deposit{value: _depositAmount}();

        // Check balance after 1 day
        vm.warp(block.timestamp + 1 days);
        uint256 balanceAfterDay1 = rebaseToken.balanceOf(user);

        // Check balance after 2 days
        vm.warp(block.timestamp + 1 days);
        uint256 balanceAfterDay2 = rebaseToken.balanceOf(user);

        // Check balance after 3 days
        vm.warp(block.timestamp + 1 days);
        uint256 balanceAfterDay3 = rebaseToken.balanceOf(user);

        // Calculate and verify interest is approximately linear
        uint256 interestDay1 = balanceAfterDay1 - _depositAmount;
        uint256 interestDay2 = balanceAfterDay2 - balanceAfterDay1;
        uint256 interestDay3 = balanceAfterDay3 - balanceAfterDay2;

        // Use assertApproxEqAbs to allow for small rounding differences
        assertApproxEqAbs(
            interestDay1,
            interestDay2,
            1,
            "Interest should be approximately linear"
        );
        assertApproxEqAbs(
            interestDay2,
            interestDay3,
            1,
            "Interest should be approximately linear"
        );
        vm.stopPrank();
    }

    function testRedeemRightAway(uint256 _redeemAmount) public {
        _redeemAmount = bound(_redeemAmount, 1e5, type(uint96).max);
        vm.startPrank(user);
        vm.deal(user, _redeemAmount);
        // 1.) deposit into vault
        vault.deposit{value: _redeemAmount}();
        // 2.) check the balance of the user
        uint256 balanceBeforeRedeem = rebaseToken.balanceOf(user);
        assertEq(balanceBeforeRedeem, _redeemAmount);
        // 3.) redeem the tokens
        vault.redeem(type(uint256).max);
        // 4.) check the balance of the user
        uint256 balanceAfterRedeem = rebaseToken.balanceOf(user);
        assertEq(balanceAfterRedeem, 0);
        // 5.) check the eth balance of the user
        uint256 ethBalance = address(user).balance;
        assertEq(ethBalance, _redeemAmount);
        vm.stopPrank();
    }

    function testRedeemAfterSomeTimeHasPassed(
        uint256 _depositAmount,
        uint256 _time
    ) public {
        _depositAmount = bound(_depositAmount, 1e5, type(uint96).max);
        _time = bound(_time, 1 days, 10000 days);
        vm.startPrank(user);
        vm.deal(user, _depositAmount);
        vault.deposit{value: _depositAmount}();

        vm.warp(block.timestamp + _time);

        uint256 balanceBeforeRedeem = rebaseToken.balanceOf(user);
        uint256 ethBalanceBeforeRedeem = address(user).balance;

        // Fund the vault with the FULL redemption amount
        vm.stopPrank();
        vm.startPrank(owner);
        vm.deal(address(vault), balanceBeforeRedeem);
        vm.stopPrank();

        // Now redeem the tokens
        vm.startPrank(user);
        vault.redeem(type(uint256).max);

        uint256 balanceAfterRedeem = rebaseToken.balanceOf(user);
        uint256 ethBalanceAfterRedeem = address(user).balance;

        // After redemption, token balance should be 0
        assertEq(
            balanceAfterRedeem,
            0,
            "Token balance should be 0 after redemption"
        );

        // ETH balance should be greater than before (due to interest)
        assertGt(
            ethBalanceAfterRedeem,
            ethBalanceBeforeRedeem,
            "ETH balance should increase after redemption"
        );

        vm.stopPrank();
    }

    function testTransfer(uint256 _amount, uint256 _sendAmount) public {
        // _amount will always be greater than _sendAmount
        _amount = bound(_amount, 2e5, type(uint96).max);
        _sendAmount = bound(_sendAmount, 1e5, _amount - 1e5);

        vm.deal(user, _amount);
        vm.startPrank(user);
        vault.deposit{value: _amount}();

        uint256 initialUserBalance = rebaseToken.balanceOf(user);
        uint256 initialUser2Balance = rebaseToken.balanceOf(user2);

        assertEq(initialUserBalance, _amount);
        assertEq(initialUser2Balance, 0);

        // owner reduces the interest rate before the transfer
        vm.stopPrank();
        vm.startPrank(owner);
        rebaseToken.setInterestRate(4e8);
        vm.stopPrank();

        // Transfer tokens from user to user2
        vm.startPrank(user);
        rebaseToken.transfer(user2, _sendAmount);
        vm.stopPrank();

        uint256 finalUserBalance = rebaseToken.balanceOf(user);
        uint256 finalUser2Balance = rebaseToken.balanceOf(user2);

        assertEq(finalUserBalance, initialUserBalance - _sendAmount);
        assertEq(finalUser2Balance, _sendAmount);

        // check user interest rates
        uint256 userInterestRate = rebaseToken.getUserInterestRate(user);
        uint256 user2InterestRate = rebaseToken.getUserInterestRate(user2);

        assertEq(userInterestRate, 5e8);
        assertEq(user2InterestRate, 5e8);
    }

    function testCannotSetInterestRateAboveCurrentRate() public {
        vm.startPrank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                RebaseToken.RebaseToken__CannotIncreaseInterestRate.selector,
                5e8,
                6e8
            )
        );
        rebaseToken.setInterestRate(6e8);
        vm.stopPrank();
    }

    function testCannotSetInterestRateIfNotOwner() public {
        vm.startPrank(user);
        vm.expectRevert();
        rebaseToken.setInterestRate(6e8);
        vm.stopPrank();
    }

    function testCannotMintIfNotOwner() public {
        vm.startPrank(user);
        vm.expectRevert();
        rebaseToken.mint(user, 100);
        vm.stopPrank();
    }

    function testCannotBurnIfNotOwner() public {
        vm.startPrank(user);
        vm.expectRevert();
        rebaseToken.burn(user, 100);
        vm.stopPrank();
    }

    function testGetPrincipalAmount(
        uint256 _depositAmount,
        uint256 _time
    ) public {
        _depositAmount = bound(_depositAmount, 1e5, type(uint96).max);
        _time = bound(_time, 1000, type(uint96).max);
        vm.startPrank(user);
        vm.deal(user, _depositAmount);
        vault.deposit{value: _depositAmount}();
        vm.warp(block.timestamp + _time);
        uint256 principalAmount = rebaseToken.principleBalanceOf(user);
        assertEq(principalAmount, _depositAmount);
        vm.stopPrank();
    }

    function testGetRebaseTokenAddress() public {
        assertEq(address(rebaseToken), address(vault.getRebaseTokenAddress()));
    }

    function testGetInterestRate() public {
        vm.startPrank(user);
        vm.deal(user, 100);
        vault.deposit{value: 100}();
        uint256 interestRate = rebaseToken.getInterestRate(user);
        assertEq(interestRate, 5e8);
        vm.stopPrank();
    }

    function testInterestRateCanOnlyDecrease() public {
        vm.startPrank(owner);
        vm.expectRevert();
        rebaseToken.setInterestRate(6e8);
        vm.stopPrank();
    }
}

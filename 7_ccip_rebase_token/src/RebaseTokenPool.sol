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

import {TokenPool} from "ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {IERC20} from "ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {Pool} from "ccip/contracts/src/v0.8/ccip/libraries/Pool.sol";
import {IRebaseToken} from "./Interfaces/IRebaseToken.sol";

contract RebaseTokenPool is TokenPool {
    constructor(
        IERC20 _token,
        address[] memory _allowList,
        address _rnmProxy,
        address _router
    ) TokenPool(_token, _allowList, _rnmProxy, _router) {}

    /// @notice Lock tokens into the pool or burn the tokens.
    /// @param lockOrBurnIn Encoded data fields for the processing of tokens on the source chain.
    /// @return lockOrBurnOut Encoded data fields for the processing of tokens on the destination chain.
    function lockOrBurn(
        Pool.LockOrBurnInV1 calldata lockOrBurnIn
    ) external returns (Pool.LockOrBurnOutV1 memory lockOrBurnOut) {
        _validateLockOrBurn(lockOrBurnIn);
        uint256 interestRate = IRebaseToken(address(i_token))
            .getUserInterestRate(lockOrBurnIn.originalSender);
        // burn the tokens
        IRebaseToken(address(i_token)).burn(address(this), lockOrBurnIn.amount); // since users transfers token to the ccip which in turn burns the tokens, we need to burn the tokens from the pool
        lockOrBurnOut = Pool.LockOrBurnOutV1({
            destTokenAddress: getRemoteToken(lockOrBurnIn.remoteChainSelector),
            destPoolData: abi.encode(interestRate)
        });
        return lockOrBurnOut;
    }

    /// @notice Releases or mints tokens to the receiver address.
    /// @param releaseOrMintIn All data required to release or mint tokens.
    /// @return releaseOrMintOut The amount of tokens released or minted on the local chain, denominated
    /// in the local token's decimals.
    /// @dev The offramp asserts that the balanceOf of the receiver has been incremented by exactly the number
    /// of tokens that is returned in ReleaseOrMintOutV1.destinationAmount. If the amounts do not match, the tx reverts.
    function releaseOrMint(
        Pool.ReleaseOrMintInV1 calldata releaseOrMintIn
    ) external returns (Pool.ReleaseOrMintOutV1 memory) {
        _validateReleaseOrMint(releaseOrMintIn);

        uint256 interestRate = abi.decode(
            releaseOrMintIn.sourcePoolData,
            (uint256)
        );

        IRebaseToken(address(i_token)).mint(
            releaseOrMintIn.receiver,
            releaseOrMintIn.amount,
            interestRate
        );

        return
            Pool.ReleaseOrMintOutV1({
                destinationAmount: releaseOrMintIn.amount
            });
    }
}

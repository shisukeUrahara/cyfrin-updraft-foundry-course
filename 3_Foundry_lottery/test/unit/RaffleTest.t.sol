// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console2} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../../test/mocks/LinkToken.sol";
import {CodeConstants} from "../../script/HelperConfig.s.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";

// Helper contract that can't receive ETH
contract NoETHReceiver {
    function enterRaffle(address raffleAddress) external payable {
        (bool success, ) = raffleAddress.call{value: msg.value}(
            abi.encodeWithSignature("enterRaffle()")
        );
        require(success, "Failed to enter raffle");
    }
}

contract RaffleTest is Test, CodeConstants {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event RequestedRaffleWinner(uint256 indexed requestId);
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed player);

    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 subscriptionId;
    bytes32 gasLane;
    uint256 automationUpdateInterval;
    uint256 raffleEntranceFee;
    uint32 callbackGasLimit;
    address vrfCoordinatorV2_5;
    LinkToken link;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant LINK_BALANCE = 100 ether;

    function setUp() external {
        // First create the VRF Coordinator and subscription
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            0.25 ether, // baseFee
            1e9, // gasPriceLink
            0.004 ether // premium fee
        );
        vm.stopBroadcast();

        // Create and fund a subscription
        uint256 subId = vrfCoordinatorMock.createSubscription();
        // uint64 subId = uint64(subIdFull); // Convert to uint64 for the Raffle contract

        // Fund the subscription with the EXACT ID returned from createSubscription
        vrfCoordinatorMock.fundSubscription(subId, 1000 ether);

        // Now deploy the raffle with this coordinator and subscription
        vm.startBroadcast();
        raffle = new Raffle(
            0.01 ether, // entranceFee
            30, // interval (30 seconds)
            address(vrfCoordinatorMock), // vrfCoordinator
            bytes32(0), // gasLane (any value for testing)
            subId, // subscriptionId (as uint64)
            100000 // callbackGasLimit
        );
        vm.stopBroadcast();

        // Add the raffle as a consumer using the EXACT ID
        vrfCoordinatorMock.addConsumer(subId, address(raffle));

        // Set our test variables
        raffleEntranceFee = 0.01 ether;
        automationUpdateInterval = 30;
        vrfCoordinatorV2_5 = address(vrfCoordinatorMock);
        subscriptionId = subId; // Store the full uint256 ID
        callbackGasLimit = 100000;

        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /*//////////////////////////////////////////////////////////////
                              ENTER RAFFLE
    //////////////////////////////////////////////////////////////*/
    function testRaffleRevertsWHenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);
        // Act / Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughEthEntered.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        raffle.enterRaffle{value: raffleEntranceFee}();
        // Assert
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        // Arrange
        vm.prank(PLAYER);

        // Act / Assert
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        // Call performUpkeep
        raffle.performUpkeep("");

        // Manually verify the state is CALCULATING
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);

        // Act / Assert
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();
    }

    /*//////////////////////////////////////////////////////////////
                              CHECKUPKEEP
    //////////////////////////////////////////////////////////////*/
    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(raffleState == Raffle.RaffleState.CALCULATING);
        assert(upkeepNeeded == false);
    }

    // Challenge 1. testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed
    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    // Challenge 2. testCheckUpkeepReturnsTrueWhenParametersGood
    function testCheckUpkeepReturnsTrueWhenParametersGood() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(upkeepNeeded);
    }

    /*//////////////////////////////////////////////////////////////
                             PERFORMUPKEEP
    //////////////////////////////////////////////////////////////*/
    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        // Act / Assert
        // It doesnt revert
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        // Arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();
        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                rState
            )
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        // Act
        vm.recordLogs();
        raffle.performUpkeep(""); // emits requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();

        // Debug the logs
        console2.log("Number of log entries:", entries.length);
        for (uint i = 0; i < entries.length; i++) {
            console2.log(
                "Log entry",
                i,
                "topics count:",
                entries[i].topics.length
            );
            for (uint j = 0; j < entries[i].topics.length; j++) {
                console2.log("  Topic", j);
                console2.logBytes32(entries[i].topics[j]);
            }
        }

        // Get the requestId from the VRF Coordinator log (first log)
        uint256 requestId = 0;
        if (entries.length >= 1 && entries[0].topics.length >= 1) {
            // The first log is from VRFCoordinatorV2_5Mock
            // The requestId is in the data part of the event
            bytes memory data = entries[0].data;
            // The first 32 bytes in the data is the requestId
            assembly {
                requestId := mload(add(data, 32))
            }
        }

        // Assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(requestId > 0);
        assert(uint256(raffleState) == 1); // 0 = open, 1 = calculating
    }

    /*//////////////////////////////////////////////////////////////
                           FULFILLRANDOMWORDS
    //////////////////////////////////////////////////////////////*/
    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep()
        public
        raffleEntered
        skipFork
    {
        // Arrange
        // Act / Assert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        // vm.mockCall could be used here...
        VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fulfillRandomWords(
            0,
            address(raffle)
        );

        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fulfillRandomWords(
            1,
            address(raffle)
        );
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney()
        public
        raffleEntered
        skipFork
    {
        address expectedWinner = address(1);

        // Arrange
        uint256 additionalEntrances = 3;
        uint256 startingIndex = 1; // We have starting index be 1 so we can start with address(1) and not address(0)

        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalEntrances;
            i++
        ) {
            address player = address(uint160(i));
            hoax(player, 1 ether); // deal 1 eth to the player
            raffle.enterRaffle{value: raffleEntranceFee}();
        }

        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 startingBalance = expectedWinner.balance;

        // Act
        vm.recordLogs();
        raffle.performUpkeep(""); // emits requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();

        // Debug the logs to see what's actually in there
        console2.log("Number of log entries:", entries.length);
        for (uint i = 0; i < entries.length; i++) {
            console2.log(
                "Log entry",
                i,
                "topics count:",
                entries[i].topics.length
            );
            for (uint j = 0; j < entries[i].topics.length; j++) {
                console2.log("  Topic", j);
                console2.logBytes32(entries[i].topics[j]);
            }
        }

        // Get the requestId from the VRF Coordinator log (first log)
        // The requestId is the second parameter in the RandomWordsRequested event
        uint256 requestId = 1; // Default fallback
        if (entries.length >= 1 && entries[0].topics.length >= 1) {
            // The first log is from VRFCoordinatorV2_5Mock
            // The requestId is in the data part of the event
            bytes memory data = entries[0].data;
            // The first 32 bytes in the data is the requestId
            assembly {
                requestId := mload(add(data, 32))
            }
        }

        console2.log("Using requestId:", requestId);

        VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fulfillRandomWords(
            requestId,
            address(raffle)
        );

        // Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = raffleEntranceFee * (additionalEntrances + 1);

        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState) == 0);
        assert(winnerBalance == startingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }

    // Test for getEntranceFee view function
    function testGetEntranceFee() public {
        assertEq(raffle.getEntranceFee(), raffleEntranceFee);
    }

    // Test for getInterval view function
    function testGetInterval() public {
        assertEq(raffle.getInterval(), automationUpdateInterval);
    }

    // Test for getPlayersLength view function
    function testGetPlayersLength() public {
        assertEq(raffle.getPlayersLength(), 0);

        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();

        assertEq(raffle.getPlayersLength(), 1);
    }

    // Test for getSubscriptionId view function
    function testGetSubscriptionId() public {
        assertEq(raffle.getSubscriptionId(), subscriptionId);
    }

    // Test for getPlayer view function
    function testGetPlayer() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();

        assertEq(raffle.getPlayer(0), PLAYER);
    }

    // Test for getRecentWinner view function
    function testGetRecentWinner() public {
        // Initially there should be no winner
        assertEq(raffle.getRecentWinner(), address(0));

        // Enter raffle and pick a winner
        address expectedWinner = PLAYER;
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();

        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();

        uint256 requestId = 1;
        if (entries.length >= 1 && entries[0].topics.length >= 1) {
            bytes memory data = entries[0].data;
            assembly {
                requestId := mload(add(data, 32))
            }
        }

        // Create a random number that will select our player as the winner
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 0; // This will pick the first player (index 0)

        vm.prank(vrfCoordinatorV2_5);
        raffle.rawFulfillRandomWords(requestId, randomWords);

        assertEq(raffle.getRecentWinner(), expectedWinner);
    }

    // Test for checkUpkeep with enough time passed but no players
    function testCheckUpkeepReturnsFalseIfEnoughTimePassedButNoPlayers()
        public
    {
        // Arrange
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    // Test for checkUpkeep with players but not enough time passed
    function testCheckUpkeepReturnsFalseIfEnoughPlayersButNotEnoughTimePassed()
        public
    {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    // Test for performUpkeep when raffle is not open
    function testPerformUpkeepRevertsIfRaffleNotOpen() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep(""); // This puts the raffle in CALCULATING state

        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                address(raffle).balance,
                1,
                1
            )
        );
        raffle.performUpkeep("");
    }

    // Test for the transfer failure case in fulfillRandomWords
    function testFulfillRandomWordsHandlesTransferFailure()
        public
        raffleEntered
        skipFork
    {
        // Arrange - Create a contract that can't receive ETH
        NoETHReceiver noEthReceiver = new NoETHReceiver();

        // Make this contract enter the raffle
        vm.deal(address(noEthReceiver), raffleEntranceFee);
        vm.prank(address(noEthReceiver));
        raffle.enterRaffle{value: raffleEntranceFee}();

        // Ensure only the non-receiving contract is in the raffle
        assertEq(raffle.getPlayersLength(), 2); // PLAYER from modifier + noEthReceiver

        // Act
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();

        uint256 requestId = 1;
        if (entries.length >= 1 && entries[0].topics.length >= 1) {
            bytes memory data = entries[0].data;
            assembly {
                requestId := mload(add(data, 32))
            }
        }

        // Create a random number that will select our non-receiving contract as the winner
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 1; // This will pick the second player (index 1)

        // Assert - This should revert with Raffle__TransferFailed
        vm.expectRevert(Raffle.Raffle__TransferFailed.selector);
        vm.prank(vrfCoordinatorV2_5);
        raffle.rawFulfillRandomWords(requestId, randomWords);
    }

    function testRawFulfillRandomWordsCanOnlyBeCalledByVRFCoordinator()
        public
        raffleEntered
        skipFork
    {
        // Arrange
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();

        uint256 requestId = 1;
        if (entries.length >= 1 && entries[0].topics.length >= 1) {
            bytes memory data = entries[0].data;
            assembly {
                requestId := mload(add(data, 32))
            }
        }

        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 123;

        // Act / Assert
        // The error is OnlyCoordinatorCanFulfill(caller, vrfCoordinator)
        vm.expectRevert(
            abi.encodeWithSelector(
                VRFConsumerBaseV2Plus.OnlyCoordinatorCanFulfill.selector,
                address(this), // The caller (this test contract)
                vrfCoordinatorV2_5 // The expected coordinator
            )
        );
        raffle.rawFulfillRandomWords(requestId, randomWords);
    }
}

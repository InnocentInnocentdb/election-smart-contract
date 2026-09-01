// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/election.sol";

contract ElectionTest is Test {
    election public e;
    address public chairman = address(this);
    address public candidate1 = address(0xC1);
    address public candidate2 = address(0xC2);
    address public voter1 = address(0xD1);
    address public voter2 = address(0xD2);
    address public voter3 = address(0xD3);

    function setUp() public {
        e = new election();
    }

    // ---- Step 1: Deployment & chairman ----

    function test_ChairmanIsDeployer() public view {
        assertEq(e.chairman(), chairman);
    }

    function test_ElectionNotStartedByDefault() public view {
        assertFalse(e.isElectionActive());
    }

    // ---- Step 2: createCandidates() ----

    function test_CreateCandidate_HappyPath() public {
        e.createCandidates(candidate1, "Alice");

        assertEq(e.getCandidateCount(), 1);
        assertEq(e.candidateIdToAddr(candidate1), 1);

        (address addr, string memory name, uint256 votes) = e.candidates(0);
        assertEq(addr, candidate1);
        assertEq(name, "Alice");
        assertEq(votes, 0);
    }

    function test_CreateCandidate_SequentialIds() public {
        e.createCandidates(candidate1, "Alice");
        e.createCandidates(candidate2, "Bob");

        assertEq(e.candidateIdToAddr(candidate1), 1);
        assertEq(e.candidateIdToAddr(candidate2), 2);
    }

    function test_RevertWhen_NonChairmanCreatesCandidate() public {
        vm.prank(candidate1);
        vm.expectRevert(election.Election__notChairmanError.selector);
        e.createCandidates(candidate1, "Alice");
    }

    function test_RevertWhen_DuplicateCandidate() public {
        e.createCandidates(candidate1, "Alice");
        vm.expectRevert(election.candidateAlreadyExists.selector);
        e.createCandidates(candidate1, "Alice Again");
    }

    // ---- Step 3: createParties() ----

    function test_CreateParty_HappyPath() public {
        uint256 id = e.createParties("Labour Party");

        assertEq(id, 1);
        assertEq(e.getPartyCount(), 1);
        assertEq(e.parties(0), "Labour Party");
    }

    function test_CreateParty_SequentialIds() public {
        e.createParties("Labour Party");
        uint256 secondId = e.createParties("Unity Party");

        assertEq(secondId, 2);
        assertEq(e.getPartyCount(), 2);
    }

    function test_RevertWhen_NonChairmanCreatesParty() public {
        vm.prank(candidate1);
        vm.expectRevert(election.Election__notChairmanError.selector);
        e.createParties("Labour Party");
    }

    function test_RevertWhen_DuplicatePartyName() public {
        e.createParties("Labour Party");
        vm.expectRevert(election.partyAlreadyExists.selector);
        e.createParties("Labour Party");
    }

    // ---- Step 4: assignCandidateToParty() ----

    function test_AssignCandidateToParty_HappyPath() public {
        e.createCandidates(candidate1, "Alice");
        e.createParties("Labour Party");

        e.assignCandidateToParty(candidate1, 1);

        assertEq(e.candidateParty(candidate1), 1);
    }

    function test_RevertWhen_NonChairmanAssignsParty() public {
        e.createCandidates(candidate1, "Alice");
        e.createParties("Labour Party");

        vm.prank(candidate1);
        vm.expectRevert(election.Election__notChairmanError.selector);
        e.assignCandidateToParty(candidate1, 1);
    }

    function test_RevertWhen_AssigningNonexistentCandidate() public {
        e.createParties("Labour Party");

        vm.expectRevert(election.candidateDoesNotExist.selector);
        e.assignCandidateToParty(candidate1, 1);
    }

    function test_RevertWhen_AssigningNonexistentParty() public {
        e.createCandidates(candidate1, "Alice");

        vm.expectRevert(election.partyDoesNotExist.selector);
        e.assignCandidateToParty(candidate1, 1);
    }

    // ---- Step 5: Election lifecycle (start/end) ----

    function test_GetElectionStarted_HappyPath() public {
        e.getElectionStarted();
        assertTrue(e.isElectionActive());
    }

    function test_RevertWhen_NonChairmanStartsElection() public {
        vm.prank(candidate1);
        vm.expectRevert(election.Election__notChairmanError.selector);
        e.getElectionStarted();
    }

    function test_RevertWhen_ElectionStartedTwice() public {
        e.getElectionStarted();
        vm.expectRevert(election.electionAlreadyStarted.selector);
        e.getElectionStarted();
    }

    function test_EndElection_HappyPath() public {
        e.getElectionStarted();
        e.endElection();
        assertFalse(e.isElectionActive());
    }

    function test_RevertWhen_EndingElectionNotStarted() public {
        vm.expectRevert(election.electionNotStarted.selector);
        e.endElection();
    }

    function test_RevertWhen_EndingElectionTwice() public {
        e.getElectionStarted();
        e.endElection();
        vm.expectRevert(election.electionAlreadyEnded.selector);
        e.endElection();
    }

    function test_RevertWhen_NonChairmanEndsElection() public {
        e.getElectionStarted();
        vm.prank(candidate1);
        vm.expectRevert(election.Election__notChairmanError.selector);
        e.endElection();
    }

    // ---- Step 6: registerVoters() ----

    function test_RegisterVoter_HappyPath() public {
        bool success = e.registerVoters(20, candidate1);

        assertTrue(success);
        assertTrue(e.is18Year(candidate1));
        assertEq(e.people(0), candidate1);
    }

    function test_RevertWhen_NonChairmanRegistersVoter() public {
        vm.prank(candidate1);
        vm.expectRevert(election.Election__notChairmanError.selector);
        e.registerVoters(20, candidate2);
    }

    function test_RevertWhen_VoterUnder18() public {
        vm.expectRevert(election.Not18yet.selector);
        e.registerVoters(17, candidate1);
    }

    // ---- Step 7: vote() ----

    function test_Vote_HappyPath() public {
        e.createCandidates(candidate1, "Alice");
        e.registerVoters(20, voter1);
        e.getElectionStarted();

        vm.prank(voter1);
        e.vote(candidate1);

        (, , uint256 votes) = e.candidates(0);
        assertEq(votes, 1);
        assertTrue(e.hasVoted(voter1));
        assertEq(e.getWinner(), 1);
    }

    function test_RevertWhen_VotingBeforeElectionStarted() public {
        e.createCandidates(candidate1, "Alice");
        e.registerVoters(20, voter1);

        vm.prank(voter1);
        vm.expectRevert("wait for your chairman, getelection started function is not called yet");
        e.vote(candidate1);
    }

    function test_RevertWhen_VotingAfterElectionEnded() public {
        e.createCandidates(candidate1, "Alice");
        e.registerVoters(20, voter1);
        e.getElectionStarted();
        e.endElection();

        vm.prank(voter1);
        vm.expectRevert(election.electionAlreadyEnded.selector);
        e.vote(candidate1);
    }

    function test_RevertWhen_VotingForUnknownCandidate() public {
        e.registerVoters(20, voter1);
        e.getElectionStarted();

        vm.prank(voter1);
        vm.expectRevert(election.thisCandidateIsDeleted.selector);
        e.vote(candidate1); // never created as a candidate
    }

    function test_RevertWhen_UnregisteredVoterVotes() public {
        e.createCandidates(candidate1, "Alice");
        e.getElectionStarted();

        vm.prank(voter1); // never registered
        vm.expectRevert(election.youAreNotRegistered.selector);
        e.vote(candidate1);
    }

    function test_RevertWhen_VotingTwice() public {
        e.createCandidates(candidate1, "Alice");
        e.registerVoters(20, voter1);
        e.getElectionStarted();

        vm.startPrank(voter1);
        e.vote(candidate1);
        vm.expectRevert(election.votedAlready.selector);
        e.vote(candidate1);
        vm.stopPrank();
    }

    // ---- Step 8: getWinner() / getWinnerDetails() ----

    function test_GetWinner_ZeroBeforeAnyVotes() public {
        e.createCandidates(candidate1, "Alice");
        assertEq(e.getWinner(), 0);
    }

    function test_GetWinnerDetails_EmptyBeforeAnyVotes() public {
        e.createCandidates(candidate1, "Alice");

        (address addr, string memory name, uint256 votes) = e.getWinnerDetails();
        assertEq(addr, address(0));
        assertEq(name, "");
        assertEq(votes, 0);
    }

    function test_GetWinnerDetails_AfterVoting() public {
        e.createCandidates(candidate1, "Alice");
        e.registerVoters(20, voter1);
        e.getElectionStarted();

        vm.prank(voter1);
        e.vote(candidate1);

        (address addr, string memory name, uint256 votes) = e.getWinnerDetails();
        assertEq(addr, candidate1);
        assertEq(name, "Alice");
        assertEq(votes, 1);
    }

    function test_GetWinner_StaysWithLeaderOnTie() public {
        e.createCandidates(candidate1, "Alice");
        e.createCandidates(candidate2, "Bob");
        e.registerVoters(20, voter1);
        e.registerVoters(20, voter2);
        e.getElectionStarted();

        vm.prank(voter1);
        e.vote(candidate1); // Alice: 1, takes the lead

        vm.prank(voter2);
        e.vote(candidate2); // Bob: 1, tied — Alice keeps the lead

        (address addr, , ) = e.getWinnerDetails();
        assertEq(addr, candidate1);
    }

    function test_GetWinner_ChangesWhenOvertaken() public {
        e.createCandidates(candidate1, "Alice");
        e.createCandidates(candidate2, "Bob");
        e.registerVoters(20, voter1);
        e.registerVoters(20, voter2);
        e.registerVoters(20, voter3);
        e.getElectionStarted();

        vm.prank(voter1);
        e.vote(candidate1); // Alice: 1, leads

        vm.prank(voter2);
        e.vote(candidate2); // Bob: 1, tied — Alice still leads

        vm.prank(voter3);
        e.vote(candidate2); // Bob: 2, now genuinely overtakes

        (address addr, string memory name, uint256 votes) = e.getWinnerDetails();
        assertEq(addr, candidate2);
        assertEq(name, "Bob");
        assertEq(votes, 2);
    }

    // ---- Step 9: removeCandidates() ----

    function test_RemoveCandidate_HappyPath() public {
        e.createCandidates(candidate1, "Alice");
        e.removeCandidates(candidate1);

        assertEq(e.candidateIdToAddr(candidate1), 0);
    }

    function test_RevertWhen_NonChairmanRemovesCandidate() public {
        e.createCandidates(candidate1, "Alice");

        vm.prank(candidate2);
        vm.expectRevert(election.Election__notChairmanError.selector);
        e.removeCandidates(candidate1);
    }

    function test_RevertWhen_RemovingNonexistentCandidate() public {
        vm.expectRevert(election.candidateDoesNotExist.selector);
        e.removeCandidates(candidate1); // never created
    }

    function test_RevertWhen_RemovingCandidateTwice() public {
        e.createCandidates(candidate1, "Alice");
        e.removeCandidates(candidate1);

        vm.expectRevert(election.candidateDoesNotExist.selector);
        e.removeCandidates(candidate1);
    }

    function test_RemovedCandidate_CannotBeVotedFor() public {
        e.createCandidates(candidate1, "Alice");
        e.registerVoters(20, voter1);
        e.getElectionStarted();
        e.removeCandidates(candidate1);

        vm.prank(voter1);
        vm.expectRevert(election.thisCandidateIsDeleted.selector);
        e.vote(candidate1);
    }
}

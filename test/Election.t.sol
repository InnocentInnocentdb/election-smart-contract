// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/election.sol";

contract ElectionTest is Test {
    election public e;
    address public chairman = address(this);
    address public candidate1 = address(0xC1);
    address public candidate2 = address(0xC2);

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract election {

    // 1. we want difereent candiditate to be able to vote
    // 2. elections to be able to be called/ started.
    // 3. we want different paties
    // 4. we want to be able to remove candidates
    // 5. we will be able to vote
    // 6. determine the winner

    error Election__notChairmanError();
    error Not18yet();
    error thisCandidateIsDeleted();
    error youAreNotRegistered();
    error votedAlready();
    error candidateAlreadyExists();
    error candidateDoesNotExist();
    error partyAlreadyExists();
    error partyDoesNotExist();
    error electionAlreadyStarted();
    error electionNotStarted();
    error electionAlreadyEnded();

    struct candidate {
        address candidateAddr;
        string candidateName;
        uint256 totalCandidateVote;
    }

    struct party {
        string partyName;
    }

    address[] public people;
    bool private isElectionStarted = false;
    bool private isElectionEnded = false;

    address public highestVoter;
    uint256 public highestVoterId;

    address public chairman;

    candidate[] public candidates;
    party[] public parties;

    mapping (address => uint256) public candidateIdToAddr;
    mapping (address => bool) public is18Year;
    mapping (address => bool) public hasVoted;
    mapping (string => bool) private partyNameTaken;
    mapping (address => uint256) public candidateParty;

    event ElectionStarted(address indexed chairman);
    event ElectionEnded(address indexed chairman);
    event CandidateCreated(uint256 indexed id, address indexed candidateAddr, string name);
    event CandidateRemoved(uint256 indexed id, address indexed candidateAddr);
    event PartyCreated(uint256 indexed id, string name);
    event CandidateAssignedToParty(address indexed candidateAddr, uint256 indexed partyId);
    event VoterRegistered(address indexed voter, uint16 age);
    event VoteCast(address indexed voter, address indexed candidateAddr, uint256 candidateId);

    modifier onlyChairman() {
        if (msg.sender != chairman) {
            revert Election__notChairmanError();
        }
        _;
    }

    constructor() {
        chairman = msg.sender;
    }

    function createCandidates(address _candidateAddress, string memory _name) public onlyChairman {
        if (candidateIdToAddr[_candidateAddress] != 0) {
            revert candidateAlreadyExists();
        }

        uint256 id = candidates.length + 1;
        candidateIdToAddr[_candidateAddress] = id;

        candidates.push(candidate({
            candidateAddr: _candidateAddress,
            candidateName: _name,
            totalCandidateVote: 0
        }));

        emit CandidateCreated(id, _candidateAddress, _name);
    }

    function getElectionStarted() public onlyChairman {
        if (isElectionStarted) {
            revert electionAlreadyStarted();
        }
        isElectionStarted = true;
        emit ElectionStarted(msg.sender);
    }

    function endElection() public onlyChairman {
        if (!isElectionStarted) {
            revert electionNotStarted();
        }
        if (isElectionEnded) {
            revert electionAlreadyEnded();
        }
        isElectionEnded = true;
        emit ElectionEnded(msg.sender);
    }

    function createParties(string memory _partyName) public onlyChairman returns (uint256) {
        if (partyNameTaken[_partyName]) {
            revert partyAlreadyExists();
        }

        uint256 id = parties.length + 1;
        parties.push(party({partyName: _partyName}));
        partyNameTaken[_partyName] = true;

        emit PartyCreated(id, _partyName);
        return id;
    }

    function assignCandidateToParty(address _candidateAddress, uint256 _partyId) public onlyChairman {
        if (candidateIdToAddr[_candidateAddress] == 0) {
            revert candidateDoesNotExist();
        }
        if (_partyId == 0 || _partyId > parties.length) {
            revert partyDoesNotExist();
        }
        candidateParty[_candidateAddress] = _partyId;
        emit CandidateAssignedToParty(_candidateAddress, _partyId);
    }

    function removeCandidates(address _candidateAddress) public onlyChairman {
        uint256 id = candidateIdToAddr[_candidateAddress];
        if (id == 0) {
            revert candidateDoesNotExist();
        }

        delete candidateIdToAddr[_candidateAddress];
        emit CandidateRemoved(id, _candidateAddress);
    }

    function registerVoters(uint16 age, address voter) public onlyChairman returns (bool) {
        if (age < 18) {
            revert Not18yet();
        }
        is18Year[voter] = true;
        people.push(voter);
        emit VoterRegistered(voter, age);
        return true;
    }

    function vote(address candidateAddress) public {
        require(isElectionStarted == true, "wait for your chairman, getelection started function is not called yet");
        if (isElectionEnded) {
            revert electionAlreadyEnded();
        }

        uint256 id = candidateIdToAddr[candidateAddress];
        if (id == 0) {
            revert thisCandidateIsDeleted();
        }

        if (!is18Year[msg.sender]) {
            revert youAreNotRegistered();
        }

        if (hasVoted[msg.sender]) {
            revert votedAlready();
        }

        candidates[id - 1].totalCandidateVote = candidates[id - 1].totalCandidateVote + 1;
        hasVoted[msg.sender] = true;

        winner(id);

        emit VoteCast(msg.sender, candidateAddress, id);
    }

    function winner(uint256 id) private {
        if (highestVoterId == 0 || candidates[id - 1].totalCandidateVote > candidates[highestVoterId - 1].totalCandidateVote) {
            highestVoterId = id;
            highestVoter = candidates[id - 1].candidateAddr;
        }
    }

    function getWinner() public view returns (uint256) {
        if (highestVoterId == 0) {
            return 0;
        }
        return candidates[highestVoterId - 1].totalCandidateVote;
    }

    function getWinnerDetails() public view returns (address winnerAddress, string memory winnerName, uint256 votes) {
        if (highestVoterId == 0) {
            return (address(0), "", 0);
        }
        candidate memory w = candidates[highestVoterId - 1];
        return (w.candidateAddr, w.candidateName, w.totalCandidateVote);
    }

    function getCandidateCount() public view returns (uint256) {
        return candidates.length;
    }

    function getPartyCount() public view returns (uint256) {
        return parties.length;
    }

    function getAllCandidates() public view returns (candidate[] memory) {
        return candidates;
    }

    function isElectionActive() public view returns (bool) {
        return isElectionStarted && !isElectionEnded;
    }
}

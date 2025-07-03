// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Voting {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    struct Candidate {
        address candidateAddress;
        string name;
        uint voteCount;
    }

    struct VotingEvent {
        string eventName;
        uint endDate;
        bool winnerDeclared;
        Candidate[] candidates;
        mapping(address => bool) hasVoted;
        uint winnerIndex;
    }

    uint public eventCount;
    mapping(uint => VotingEvent) private votingEvents;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier eventExists(uint eventId) {
        require(eventId < eventCount, "Voting event does not exist.");
        _;
    }

    modifier beforeDeadline(uint eventId) {
        require(block.timestamp < votingEvents[eventId].endDate, "Voting has ended.");
        _;
    }

    modifier afterDeadline(uint eventId) {
        require(block.timestamp >= votingEvents[eventId].endDate, "Voting is still ongoing.");
        _;
    }

    function createVotingEvent(string memory _name, uint _durationInMinutes) public onlyOwner {
        VotingEvent storage newEvent = votingEvents[eventCount];
        newEvent.eventName = _name;
        newEvent.endDate = block.timestamp + (_durationInMinutes * 1 minutes);
        newEvent.winnerDeclared = false;
        eventCount++;
    }

    function registerCandidate(uint eventId, address _candidateAddress, string memory _name)
        public onlyOwner eventExists(eventId) beforeDeadline(eventId)
    {
        votingEvents[eventId].candidates.push(Candidate({
            candidateAddress: _candidateAddress,
            name: _name,
            voteCount: 0
        }));
    }

    function vote(uint eventId, uint candidateIndex)
        public eventExists(eventId) beforeDeadline(eventId)
    {
        VotingEvent storage ve = votingEvents[eventId];
        require(!ve.hasVoted[msg.sender], "You have already voted.");
        require(candidateIndex < ve.candidates.length, "Invalid candidate.");

        ve.candidates[candidateIndex].voteCount += 1;
        ve.hasVoted[msg.sender] = true;
    }

    function timeLeft(uint eventId) public view eventExists(eventId) returns (uint) {
        if (block.timestamp >= votingEvents[eventId].endDate) {
            return 0;
        }
        return votingEvents[eventId].endDate - block.timestamp;
    }

    function getWinner(uint eventId)
        public eventExists(eventId) afterDeadline(eventId) returns (string memory, address, uint)
    {
        VotingEvent storage ve = votingEvents[eventId];
        require(!ve.winnerDeclared, "Winner already declared.");

        uint maxVotes = 0;
        uint winnerIdx = 0;

        for (uint i = 0; i < ve.candidates.length; i++) {
            if (ve.candidates[i].voteCount > maxVotes) {
                maxVotes = ve.candidates[i].voteCount;
                winnerIdx = i;
            }
        }

        ve.winnerIndex = winnerIdx;
        ve.winnerDeclared = true;

        Candidate memory winner = ve.candidates[winnerIdx];
        return (winner.name, winner.candidateAddress, winner.voteCount);
    }

    // ✅ New Functions Below

    function getCandidate(uint eventId, uint index)
        public view eventExists(eventId)
        returns (string memory, address, uint)
    {
        Candidate memory c = votingEvents[eventId].candidates[index];
        return (c.name, c.candidateAddress, c.voteCount);
    }

    function getCandidateCount(uint eventId)
        public view eventExists(eventId) returns (uint)
    {
        return votingEvents[eventId].candidates.length;
    }

    function getEvent(uint eventId)
        public view eventExists(eventId)
        returns (string memory, uint, bool)
    {
        VotingEvent storage ve = votingEvents[eventId];
        return (ve.eventName, ve.endDate, ve.winnerDeclared);
    }
}

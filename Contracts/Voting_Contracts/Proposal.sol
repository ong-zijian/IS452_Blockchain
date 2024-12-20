// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Proposal {
    string public name;
    string public description;
    uint public deadline;
    uint public yesVotes;
    uint public noVotes;
    bool public votingEnded;

    event VotingEnded(uint proposalId, uint yesVotes, uint noVotes);

    constructor(string memory _name, string memory _description, uint _duration) {
        name = _name;
        description = _description;
        deadline = block.timestamp + _duration;
        votingEnded = false;
    }

    function endVoting() external {
        require(block.timestamp > deadline, "Voting period not yet over");
        require(!votingEnded, "Voting already ended");
        votingEnded = true;
        emit VotingEnded(uint(keccak256(abi.encodePacked(name))), yesVotes, noVotes);
    }

    function recordVote(bool voteYes, uint weight) external {
        require(block.timestamp < deadline, "Voting has ended");
        require(!votingEnded, "Voting has ended");
        
        if (voteYes) {
            yesVotes += weight;
        } else {
            noVotes += weight;
        }
    }

    function getResults() external view returns (string memory outcome, uint yesVotesCount, uint noVotesCount, bool votingStatus) {
        yesVotesCount = yesVotes;
        noVotesCount = noVotes;
        votingStatus = votingEnded;

        if (yesVotes > noVotes) {
            outcome = "Yes votes won";
        } else if (noVotes > yesVotes) {
            outcome = "No votes won";
        } else {
            outcome = "It's a tie";
        }

        return (outcome, yesVotesCount, noVotesCount, votingStatus);
    }

}

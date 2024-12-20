// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./Proposal.sol";
import "./Master.sol";

contract Voter {
    mapping(uint => mapping(address => bool)) public hasVoted;

    event VoteCasted(uint proposalId, address voter, bool vote);

    modifier onlyShareholders(Master masterContract) {
        require(masterContract.shareholderTokens(msg.sender) > 0, "You do not have voting rights");
        _;
    }

    function castVote(Master masterContract, uint proposalId, bool voteYes) external onlyShareholders(masterContract) {
        Proposal proposal = masterContract.getProposal(proposalId);
        require(block.timestamp < proposal.deadline(), "Voting has ended");
        require(!proposal.votingEnded(), "Voting has ended");

        uint weight = masterContract.shareholderTokens(msg.sender);
        require(!hasVoted[proposalId][msg.sender], "You have already voted");

        proposal.recordVote(voteYes, weight);
        hasVoted[proposalId][msg.sender] = true;

        emit VoteCasted(proposalId, msg.sender, voteYes);
    }

    function hasUserVoted(uint proposalId, address user) public view returns (bool) {
        return hasVoted[proposalId][user];
    }
}

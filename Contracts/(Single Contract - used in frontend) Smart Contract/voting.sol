//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract VotingSystem {

    struct Proposal {
        string name;
        string description;
        uint deadline;
        uint yesVotes;
        uint noVotes;
        bool votingEnded;
    }

    struct Vote {
        address voter;
        bool vote; // true for yes, false for no
        uint256 weight; // number of tokens used for the vote
    }

    // Admin address
    address public admin;

    // Mapping shareholder addresses to their token balance
    mapping(address => uint) public shareholderTokens;

    // Mapping for proposals
    mapping(uint => Proposal) public proposals;
    uint public proposalCount;  // Keeps track of proposals

    // Mapping for votes cast per proposal
    mapping(uint => Vote[]) public proposalVotes;

    // v1.2: mapping for the users that has already voted
    mapping(uint => mapping(address => bool)) public hasVoted;

    // Events for logging
    event ProposalCreated(uint id, string name, string description, uint deadline);
    event VoteCasted(uint proposalId, address voter, bool vote);
    event VotingEnded(uint proposalId, uint yesVotes, uint noVotes);

    // Modifier to check if the sender is the admin
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can perform this action");
        _;
    }

    // Modifier to check if a proposal is still accepting votes
    modifier onlyDuringVoting(uint proposalId) {
        require(block.timestamp < proposals[proposalId].deadline, "Voting has ended for this proposal");
        _;
    }

    // Modifier to check if the user is a shareholder
    modifier onlyShareholders() {
        require(shareholderTokens[msg.sender] > 0, "You do not have voting rights");
        _;
    }

    // Constructor to initialize the admin
    constructor() {
        admin = msg.sender;  // The deployer of the contract is the admin
    }

    // Admin function to assign tokens to shareholders
    function assignTokens(address shareholder, uint amount) public onlyAdmin {
        shareholderTokens[shareholder] = amount;
    }

    // Admin function to create a proposal
    function createProposal(string memory description, string memory name, uint duration) public onlyAdmin {
        proposals[proposalCount] = Proposal({
            name:name,
            description: description,
            deadline: block.timestamp + duration,
            yesVotes: 0,
            noVotes: 0,
            votingEnded: false
        });
        emit ProposalCreated(proposalCount, name, description, block.timestamp + duration);
        proposalCount++;
    }

    // Shareholder function to cast a vote on a proposal
    function vote(uint proposalId, bool voteYes) public onlyDuringVoting(proposalId) onlyShareholders {
        // v1.2: check if the user has already voted
        require(!hasVoted[proposalId][msg.sender], "You have already voted on this proposal");
        
        uint256 weight = shareholderTokens[msg.sender];
        if (voteYes) {
            proposals[proposalId].yesVotes += weight;
        } else {
            proposals[proposalId].noVotes += weight;
        }

        // Record the vote
        proposalVotes[proposalId].push(Vote({
            voter: msg.sender,
            vote: voteYes,
            weight: weight
        }));
        
        // v1.2: added a check so that we know the user voted
        hasVoted[proposalId][msg.sender] = true;

        emit VoteCasted(proposalId, msg.sender, voteYes);
    }

    // Admin function to end voting manually (can be automated by checking time)
    function endVoting(uint proposalId) public onlyAdmin {
        require(block.timestamp > proposals[proposalId].deadline, "Voting period not yet over");
        require(!proposals[proposalId].votingEnded, "Voting has already ended");

        proposals[proposalId].votingEnded = true;
        emit VotingEnded(proposalId, proposals[proposalId].yesVotes, proposals[proposalId].noVotes);
    }

    // Function to get the result of a proposal
    function getProposalResults(uint proposalId) public view returns (string memory description, uint yesVotes, uint noVotes, bool ended) {
        Proposal memory p = proposals[proposalId];
        return (p.description, p.yesVotes, p.noVotes, p.votingEnded);
    }

    // Function to calculate the percentage of yes and no votes
    function getVotePercentages(uint proposalId) public view returns (uint yesPercentage, uint noPercentage) {
        Proposal memory p = proposals[proposalId];
        uint totalVotes = p.yesVotes + p.noVotes;

        // If no votes have been cast, return 0% for both
        if (totalVotes == 0) {
            return (0, 0);
        }

        // Calculate percentages
        yesPercentage = (p.yesVotes * 100) / totalVotes;
        noPercentage = (p.noVotes * 100) / totalVotes;
    }

    // Function to retrieve all votes for a given proposal
    function getProposalVotes(uint proposalId) public view returns (Vote[] memory) {
        return proposalVotes[proposalId];
    }

    // Admin function to transfer admin privileges to a new address
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "New admin address cannot be zero address");
        admin = newAdmin;
    }
}


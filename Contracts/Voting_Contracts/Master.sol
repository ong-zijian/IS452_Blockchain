// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Proposal.sol";
import "./Voter.sol";

contract Master is Pausable, ReentrancyGuard {
    address public admin;  // Add admin manually
    mapping(address => uint) public shareholderTokens;
    Proposal[] public proposals;
    Voter public voter;

    event ProposalCreated(uint id, string name, string description, uint deadline);
    event ShareholderRemoved(address shareholder);
    event TokensAssigned(address shareholder, uint amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can perform this action");
        _;
    }

    modifier onlyShareholders() {
        require(shareholderTokens[msg.sender] > 0, "You do not have voting rights");
        _;
    }

    constructor() {
        admin = msg.sender;  // Set the deployer as the admin
        voter = new Voter();
    }

    // Assign tokens to a shareholder
    function assignTokens(address shareholder, uint amount) public onlyAdmin whenNotPaused nonReentrant {
        shareholderTokens[shareholder] = amount;
        emit TokensAssigned(shareholder, amount);
    }

    // Create a proposal
    function createProposal(string memory name, string memory description, uint duration) public onlyAdmin whenNotPaused nonReentrant {
        Proposal proposal = new Proposal(name, description, duration);
        proposals.push(proposal);
        emit ProposalCreated(proposals.length - 1, name, description, block.timestamp + duration);
    }

    // Get a proposal by its index
    function getProposal(uint index) public view returns (Proposal) {
        return proposals[index];
    }

    // Transfer admin rights to a new admin
    function transferAdmin(address newAdmin) public onlyAdmin nonReentrant {
        require(newAdmin != address(0), "New admin address cannot be zero address");
        admin = newAdmin;
    }

    // Remove a shareholder by setting their token count to 0
    function removeShareholder(address shareholder) public onlyAdmin whenNotPaused nonReentrant {
        require(shareholderTokens[shareholder] > 0, "The address does not have any tokens");
        delete shareholderTokens[shareholder];
        emit ShareholderRemoved(shareholder);
    }

    // Pause the contract (disable certain functions)
    function pause() public onlyAdmin {
        _pause(); // Pauses the contract
    }

    // Unpause the contract (enable functions)
    function unpause() public onlyAdmin {
        _unpause(); // Unpauses the contract
    }
}

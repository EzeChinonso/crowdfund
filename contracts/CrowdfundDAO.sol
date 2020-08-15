//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;

import "@nomiclabs/buidler/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Crowdfund.sol";
import "./Token.sol";

contract CrowdDAO is Ownable{ 
    using SafeMath for uint;
/* Contract Variables */ 

    CRToken public daoToken; 
    Crowdfund public daoCrowdfund;
    uint256 public minimumQuorum; 
    uint256 public marginForMajority; 
    uint256 public votingPeriod; 
    mapping (uint256 => Proposal) proposals;
    uint256[] public ProposalID; 
    uint256 public proposalsNumber = 0;
    Withdrawal[] public withdrawals; 
    uint256 public withdrawalsNumber = 0; 
    uint256 withdrawalTimeWindow; 
    uint256 withdrawalMaxAmount;
    bool isDissolved = false; 
    uint256 dissolvedBalance; 
    mapping (address => bool) accountPayouts;
    /* Contract Events */ 
    event ProposalAdded(address indexed beneficiary, uint256 etherAmount, string description, uint256 proposalID); 
    event Voted(uint256 indexed proposalID, address indexed voter, bool indexed inSupport, uint256 voterTokens, string justificationText);
    event ProposalTallied(uint256 indexed proposalID, bool indexed quorum, bool indexed result); 
    event ProposalExecuted(uint256 indexed proposalID); 
    event MoneyWithdrawn(address indexed beneficiary, uint256 amount); 
    event BalanceToDissolve(uint256 amount);
    /* Contract Structures */ 
    enum ProposalState { Proposed, NoQuorum, Rejected, Passed, Executed}
    enum Voting { started, ended }
    struct Proposal { 
        /* Proposal content */ 
        address beneficiary; 
        uint256 etherAmount; 
        string description; 
        bytes32 proposalHash;
    /* Proposal state */ 
        ProposalState state;
    /* Voting state */ 
        uint256 votingDeadline; 
        Vote[] votes; 
        uint256 votesNumber; 
        mapping (address => bool) voted;
    }
    struct Vote { 
        address voter; 
        bool inSupport; 
        uint256 voterTokens; 
        string justificationText; 
        
    }
    struct Withdrawal { 
        address beneficiary; 
        uint256 amount; 
        uint256 time; 
        
    }

 
    constructor( address _crowdfundModerator, uint256 _minimumQuorumInPercents, uint256 _marginForMajorityInPercents, uint256 _votingPeriodInMinutes, uint256 _withdrawalTimeWindowInMinutes, uint256 _withdrawalMaxAmountInWei ) public payable { 
        daoToken = new CRToken(); 
        daoCrowdfund = new Crowdfund(address(this), _crowdfundModerator, 100, 1000, 10 * 24 * 60, 5, 1, address(daoToken));
    /* Setup rules */ 
        minimumQuorum = _minimumQuorumInPercents; 
        marginForMajority = _marginForMajorityInPercents; 
        votingPeriod = _votingPeriodInMinutes * 1 minutes; 
        withdrawalTimeWindow = _withdrawalTimeWindowInMinutes * 1 minutes; 
        withdrawalMaxAmount = _withdrawalMaxAmountInWei * 1 wei;
    }

    fallback() external payable onlyActiveDAO {}
    
    /* Change Withdraw Tracking rules */ 
    function setWithdrawalMaxAmount(uint _withdrawalMaxAmountInWei) public { 
        require(msg.sender == address(this), "You don't have authorization for this 😎");
        withdrawalMaxAmount = _withdrawalMaxAmountInWei; 
        }

/* Change Voting majority required */ 
    function setMarginForMajority(uint _marginForMajorityInPercents) public { 
        require(msg.sender == address(this), "You don't have authorization for this 😎");
        marginForMajority = _marginForMajorityInPercents;
    }
    function setMinimumQuorum(uint _minimumQuorumInPercents) public {
/* Change Voting quorum required */ 
        require(msg.sender == address(this), "You don't have authorization for this 😎");
        minimumQuorum = _minimumQuorumInPercents; 
        }
    function setWithdrawalTimeWindow(uint _withdrawalTimeWindowInMinutes) public{
        require(msg.sender == address(this), "You don't have authorization for this 😎");
        withdrawalTimeWindow = _withdrawalTimeWindowInMinutes;
    }
    function setVotingPeriod(uint _votingPeriodInMinutes) public{
        require(msg.sender == address(this), "You don't have authorization for this 😎");
        votingPeriod = _votingPeriodInMinutes;
    }
    
    //function getTransactionHash(string memory _function) public pure returns(bytes4) {
    //    return bytes4(keccak256(abi.encodePacked(_function)));
    //}
    function getProposalHash( address _beneficiary, uint256 _etherAmountInWei, bytes memory _transactionBytecode ) public pure returns (bytes32) { 
        return keccak256(abi.encodePacked(_beneficiary, _etherAmountInWei, _transactionBytecode)); 
    }

    function createProposal( address _beneficiary, uint256 _etherAmountInWei, string memory _description,bytes memory  _transactionBytecode) public onlyDAOMember onlyActiveDAO returns (uint256 proposalID) { 
        proposalID = ProposalID.length; 
        proposalsNumber = proposalID + 1;
        Proposal memory p = proposals[proposalID];
        p.beneficiary = _beneficiary; 
        p.etherAmount = _etherAmountInWei; 
        p.description = _description; 
        p.proposalHash = getProposalHash(_beneficiary, _etherAmountInWei, _transactionBytecode); 
        p.state = ProposalState.Proposed; 
        p.votingDeadline = now + votingPeriod * 1 seconds; 
        p.votesNumber = 0;
        ProposalID.push(proposalID);
        //TODO:
        //Figure out how to push this to the Proposals array
        p = Proposal(proposals[proposalID].beneficiary,proposals[proposalID].etherAmount,proposals[proposalID].description,proposals[proposalID].proposalHash,proposals[proposalID].state,proposals[proposalID].votingDeadline,proposals[proposalID].votes,proposals[proposalID].votesNumber);
        
        emit ProposalAdded(_beneficiary, _etherAmountInWei, _description, proposalID);
        return proposalID;
    }

    
    
    function vote( uint256 _proposalID, bool _inSupport, string memory _justificationText ) public  onlyDAOMember onlyActiveDAO { 
        Proposal storage p = proposals[_proposalID];
        require (p.state == ProposalState.Proposed, "This proposal has not been made yet 💩"); 
        require (p.voted[msg.sender] == false, "You've voted before, Are you trying to rig? 🤢");
        uint voterBalance = daoToken.balanceOf(msg.sender); 
        daoToken.blockAccount(msg.sender);
        p.voted[msg.sender] = true; 
        p.votes.push(Vote(msg.sender, _inSupport, voterBalance, _justificationText)); 
        p.votesNumber += 1;
        emit Voted(_proposalID, msg.sender, _inSupport, voterBalance, _justificationText);
    }
 
    function finishProposalVoting(uint256 _proposalID) public onlyDAOMember onlyActiveDAO { 
        Proposal memory p = proposals[_proposalID];
    /* Check is voting deadline reached */ 
        require(now > p.votingDeadline, "voting is over 😈"); 
        require(p.state == ProposalState.Proposed, "This proposal has not been made yet 😴");
        daoToken.unblockAccount(msg.sender);
        uint256 _votesNumber = p.votes.length; 
        uint256 tokensFor = 0; 
        uint256 tokensAgainst = 0;
    /* Count votes */ 
        for (uint256 i = 0; i < _votesNumber; i++) { 
            if (p.votes[i].inSupport) { 
                tokensFor += p.votes[i].voterTokens; 
            } else { 
                tokensAgainst += p.votes[i].voterTokens; 
            }  
        }
    
    /* Check if quorum is not reached */ 
        if ((tokensFor + tokensAgainst) < daoToken.totalSupply().mul(minimumQuorum).div(100)) { 
            p.state = ProposalState.NoQuorum; 
            emit ProposalTallied(_proposalID, false, false); 
            return; 
            
        }
    /* Check if majority is not reached */ 
        if (tokensFor < (tokensFor + tokensAgainst).mul(marginForMajority).div(100)) { 
            p.state = ProposalState.Rejected; 
            emit ProposalTallied(_proposalID, true, false); 
            return; 
        }
    /* Else Validate */ 
        else { 
            p.state = ProposalState.Passed; 
            emit ProposalTallied(_proposalID, true, true);
            return;
    }
        
}

    function executeProposal(uint256 _proposalID, bytes memory _transactionBytecode) public onlyDAOMember onlyActiveDAO { 
        Proposal memory p = proposals[_proposalID];
        require (p.state == ProposalState.Passed, "This proposal has not been made yet 😁😶☹😤");
        require(p.state != ProposalState.Executed, "This proposal has been executed already 😮");
        bytes32 proposalHashForCheck = bytes32(getProposalHash(p.beneficiary, p.etherAmount, _transactionBytecode)); 
        require (p.proposalHash == proposalHashForCheck);
        p.state = ProposalState.Executed; 
        (bool success, bytes memory response) = (p.beneficiary.call{value: (p.etherAmount * 1 wei)}(_transactionBytecode));
        require(success, "Damn it, seems that wasn't successful 😰");
        console.logBytes(response);
        emit ProposalExecuted(_proposalID);
}
 

    function withdraw(uint256 _amount) public onlyOwner onlyActiveDAO { 
        /* Add new record for the withdrawal */ 
        uint256 withdrawalID = withdrawals.length; 
 
        withdrawalsNumber = withdrawalID + 1;
        withdrawals[withdrawalID].beneficiary = msg.sender; 
        withdrawals[withdrawalID].amount = _amount; 
        withdrawals[withdrawalID].time = now;
        uint256 slidingWindowStartTimestamp = now - withdrawalTimeWindow;
        uint256 withdrawalsAmount = 0; 
        for (uint256 _withdrawalID = withdrawalsNumber - 1; _withdrawalID >= 0; _withdrawalID--) { 
            if (withdrawals[_withdrawalID].time < slidingWindowStartTimestamp) { 
                break; 
                } 
            withdrawalsAmount = withdrawalsAmount.add(withdrawals[_withdrawalID].amount);
        } 
        if (withdrawalsAmount > withdrawalMaxAmount) { 
            revert();
        }
        msg.sender.transfer(_amount);
        withdrawals.push(Withdrawal(withdrawals[withdrawalID].beneficiary, withdrawals[withdrawalID].amount, withdrawals[withdrawalID].time ));
        emit MoneyWithdrawn(msg.sender, _amount);
}

    function dissolveContract() public onlyActiveDAO { 
        require(msg.sender == address(this), "You don't have authorization for this 😎");
        isDissolved = true; 
        dissolvedBalance = address(this).balance; 
        emit BalanceToDissolve(dissolvedBalance);
    }
    
 
    function withdrawDissolvedFunds() public onlyDissolvedDAO onlyDAOMember { 
        require(accountPayouts[msg.sender] == false, "You've recieved your stash bro 🙄");
        accountPayouts[msg.sender] = true; 
        daoToken.blockAccount(msg.sender);
        uint tokenBalance = daoToken.balanceOf(msg.sender); 
        uint ethToSend = tokenBalance.div(daoToken.totalSupply()).mul(dissolvedBalance);
        msg.sender.transfer(ethToSend);
}  
 
    modifier onlyDAOMember {
        require(daoToken.balanceOf(msg.sender) > 0, "Dude you've got no tokens🥱🍟");
        _; }

    modifier onlyActiveDAO { 
        require(isDissolved == false, "C'mmon man the DAO is still active 🤡"); 
    _; 
    }

    modifier onlyDissolvedDAO {
         require(isDissolved == true, "Sorry, the DAO is no longer active 😥"); 
    _; 
    }
}


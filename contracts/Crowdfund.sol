//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;

//import "@nomiclabs/buidler/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/math/SafeMath.sol";
//import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Token.sol";



contract Crowdfund is Ownable {
  using SafeMath for uint;

  //uint256 private _totalSupply;
  
  address payable beneficiary; 
  address public moderator; 
  uint256 public fundingGoal; 
  uint256 public fundingCap; 
  uint256 public deadline;

  CRToken public CrowdfundToken;
  uint256 tokenPriceNumerator;
  uint256 tokenPriceDenominator;
  
  uint256 public amountRaised;
  mapping (address => uint256) public balances; 
  CrowdfundState public crowdfundState;

  /* Contract Events */
  event FundsReceived(address indexed backer, uint256 amount); 
  event FundsWithdrawn(address indexed backer, uint256 amount); 
  event CrowdfundSuccessful(bool isSuccess); 
  event CrowdFundsForwarded(address indexed beneficiary);

  /* Contract Structures */ 
  enum CrowdfundState { 
    Running, 
    Success, 
    Failed, 
    Forwarded 
    }

    

  constructor ( 
    address payable _crowdfundBeneficiary, address _crowdfundModerator, uint256 _fundingGoalInEthers,uint256 _fundingCapInEthers, uint256 _durationInMinutes, uint256 _tokenPriceNumerator, uint256 _tokenPriceDenominator, address _tokenRewardAddress) public { 
      beneficiary = _crowdfundBeneficiary;
      moderator = _crowdfundModerator;
      fundingGoal = _fundingGoalInEthers * 1 ether; 
      fundingCap = _fundingCapInEthers * 1 ether; 
      deadline = now + _durationInMinutes * 1 minutes; 
      tokenPriceNumerator = _tokenPriceNumerator;
      tokenPriceDenominator = _tokenPriceDenominator;
      CrowdfundToken = CRToken(_tokenRewardAddress); 
      }
      

  
  fallback() external payable onlyRunningCrowdfund { 
    uint256 amountEth = msg.value; 
    uint256 rate = amountEth.mul(tokenPriceNumerator).div(tokenPriceDenominator); 
    uint256 investedFunds = balances[msg.sender];
    balances[msg.sender] = investedFunds.add(amountEth); 
    amountRaised = amountRaised.add(amountEth); 
    CrowdfundToken.mint(msg.sender, rate);
    //console.log(investedFunds, balanceOf[msg.sender]);
    
    emit FundsReceived(msg.sender, amountEth);
  }



  function finishCrowdfund() public onlyRunningCrowdfund { 
    if (now < deadline && amountRaised < fundingGoal) { 
     revert("The crowdfund is not yet over and we haven't reached our goal either 🙃");
    } else if (now >= deadline && amountRaised < fundingGoal) { 
        crowdfundState = CrowdfundState.Failed; 
        CrowdfundToken.finishMinting(); 
        CrowdfundSuccessful(false);
    } else if (msg.sender == moderator && amountRaised >= fundingGoal) { 
        crowdfundState = CrowdfundState.Success; 
        CrowdfundToken.finishMinting(); 
        CrowdfundSuccessful(true); 
    } else if (amountRaised >= fundingCap) { 
        crowdfundState = CrowdfundState.Success; 
        CrowdfundToken.finishMinting(); 
        CrowdfundSuccessful(true); 
    } else { 
      revert("Seems the party isn't over yet"); 
      }
  }
 
 
  function withdraw() public onlyFailedCrowdfund { 
    uint256 amountEth = balances[msg.sender]; 
    CrowdfundToken.burnFrom(msg.sender,balances[msg.sender]);
    if (amountEth > 0) { 
        msg.sender.transfer(amountEth); 
        emit FundsWithdrawn(msg.sender, amountEth); 
        
    } 
      
  }

  
  function forwardCrowdfundFunding()public onlySuccessfulCrowdfund onlyCrowdfundModerator { 
    crowdfundState = CrowdfundState.Forwarded; 
    beneficiary.transfer(amountRaised); 
    transferOwnership(beneficiary); 
    CrowdFundsForwarded(beneficiary); 
    }
    
  modifier onlyCrowdfundModerator() { 
    require(msg.sender == moderator, "Sorry, you don't have admin priviledges 😎"); 
    _; 
    }

  modifier onlyRunningCrowdfund() { 
    require(crowdfundState == CrowdfundState.Running, "Hehehe, The fun is over 😁");
    _; 
    }

  modifier onlySuccessfulCrowdfund() { 
    require(crowdfundState == CrowdfundState.Success, "Damn it, the crowdfund failed man 😥" );
    _; 
    }
  
  modifier onlyFailedCrowdfund() { 
    require(crowdfundState == CrowdfundState.Failed, "C'mmon man, the crowdfunding was successful 🎉🎉"); 
    _;
  }
}

const assert = require("assert");
const {expect} = require("chai")

describe('CrowdfundDAO', function () {
    let crowdfundDAO;
    const beneficiary = '0xc783df8a850f42e7F7e57013759C285caa701eB6';
    beforeEach(async function (){
        
        this.timeout(30000)
        const CrowdfundDAO = await ethers.getContractFactory("CrowdDAO");
        crowdfundDAO = await CrowdfundDAO.deploy(beneficiary, 50, 65, 30, 40, 10000 );
        await crowdfundDAO.deployed();
    })
    it('.createProposal', async function (){
        //const crwd = await crowdfundDAO.createProposal(beneficiary, 50000, 'extend voting deadline', '566fd2f2'));
        //await crwd.proposalID.then((res)=>{console.log(res)})

    })
})
//address _beneficiary, uint256 _etherAmountInWei, string memory _description,bytes memory  _transactionBytecode
//address _crowdfundModerator, uint256 _minimumQuorumInPercents, uint256 _marginForMajorityInPercents, 
//uint256 _votingPeriodInMinutes, uint256 _withdrawalTimeWindowInMinutes, uint256 _withdrawalMaxAmountInWei 
//0x3db79f7AEaE37b9Ab8548b42f94F1f36cbaae5a7
//beneficiary, 50, 65, 30, 40, 10000 
//address _beneficiary, uint256 _etherAmountInWei, string memory _description,bytes memory  _transactionBytecode
//beneficiary, 50000, 'extend voting deadline', 'hhghgghg'
//
//'0xc783df8a850f42e7F7e57013759C285caa701eB6', 50000, 'extend voting deadline', '566fd2f2'
//"0x3db79f7AEaE37b9Ab8548b42f94F1f36cbaae5a7","60000","'test stuff'","566fd2f2" //createProposal
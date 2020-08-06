const assert = require("assert");
const {expect} = require("chai");
//const { ethers } = require("ethers");

describe('My Crowdfund Contract', function () {
    let crowd;
    beforeEach(async function (){
        this.timeout(60000)
        const beneficiary = '0xc783df8a850f42e7F7e57013759C285caa701eB6'
        const Crowd = await ethers.getContractFactory("Crowdfund");
        crowd = await Crowd.deploy(beneficiary, beneficiary, 60, 50, 30, 5, 1, beneficiary );
        await crowd.deployed();
    })
    it('name', async function () {
  

        await crowd.CrowdfundToken().then((res)=>{console.log(res)});
        
    })
})

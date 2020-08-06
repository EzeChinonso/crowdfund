const assert = require("assert");
const {expect} = require("chai");
//const { ethers } = require("ethers");

describe('My Crowdfund Contract', function () {
    let crowd;
    beforeEach(async function (){
        this.timeout(60000)
        const addr = '0xc783df8a850f42e7F7e57013759C285caa701eB6'
        const Crowd = await ethers.getContractFactory("Crowdfund");
        crowd = await Crowd.deploy(addr, addr, 60, 50, 30, 5, 1, addr );
        await crowd.deployed();
    })
    it('.finishCrowdfund', async function () {
  

        await crowd.finishCrowdfund().then((res)=>{console.log(res)});
        
    })
})

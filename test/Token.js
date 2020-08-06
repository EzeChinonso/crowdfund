const assert = require("assert");
const {expect} = require("chai");
//const { ethers } = require("ethers");

describe('My Token Contract', function () {
    let token;
    beforeEach(async function (){
        this.timeout(30000)
        const Token = await ethers.getContractFactory("CRToken");
        token = await Token.deploy();
        await token.deployed();
    })
    it('name', async function () {
  

        await token.name().then((res)=>{console.log(res)});
        await token.symbol().then((res)=>{console.log(res)})
        
    })
    it('.totalSupply', async function () {
        await token.totalSupply().then((res)=>{console.log(res.toNumber())})
    })
})
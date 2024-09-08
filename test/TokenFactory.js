const { expect } = require("chai");
const hre = require("hardhat");


describe("TokenFactory", function () {
    it("Should create the meme token successfully", async function () {
        const tokenFactoryContract = await hre.ethers.deployContract("TokenFactory");
        const tx = await tokenFactoryContract.createMemeToken("Dogecoin", "DOGE", "This is a doge token, much wow", "doge.png", {value: hre.ethers.parseEther("0.011")});
        
        })

        it("Should allow a user to purchase the meme token", async function() {
            const tokenCt = await hre.ethers.deployContract("TokenFactory");
            const tx1 = await tokenCt.createMemeToken("Test", "TEST", "img://img.png", "hello there", {
                value: hre.ethers.parseEther("0.011")
            });
            const memeTokenAddress = await tokenCt.memeTokenAddresses(0)
            const tx2 = await tokenCt.buyMemeToken(memeTokenAddress, 800000, {
                value: hre.ethers.parseEther("24")
            });
            // const memecoins = await tokenCt.getAllMemeTokens();
            // console.log("Memecoins ", memecoins)
        })
})

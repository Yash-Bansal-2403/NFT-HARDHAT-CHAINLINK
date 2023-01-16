//some of the tests are -
const { assert } = require("chai")
const { network, deployments, ethers } = require("hardhat")
const { developmentChains } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip//skip if on testnet
    : describe("Basic NFT Unit Tests", function () {
        let basicNft, deployer

        beforeEach(async () => {
            accounts = await ethers.getSigners()// could also do with getNamedAccounts
            deployer = accounts[0]
            await deployments.fixture(["basicnft"])// Deploys modules with the tags "basicnft"
            basicNft = await ethers.getContract("BasicNft")//instance of Basicnft contract
        })

        describe("Constructor", () => {
            it("Initializes the NFT Correctly.", async () => {
                const name = await basicNft.name()
                const symbol = await basicNft.symbol()
                const tokenCounter = await basicNft.getTokenCounter()
                assert.equal(name, "Dogie")
                assert.equal(symbol, "DOG")
                assert.equal(tokenCounter.toString(), "0")
            })
        })
        //test02
        describe("Mint NFT", () => {
            beforeEach(async () => {
                const txResponse = await basicNft.mintNft()
                await txResponse.wait(1)
            })
            it("Allows users to mint a NFT, and updates appropriately", async function () {
                const tokenURI = await basicNft.tokenURI(0)
                const tokenCounter = await basicNft.getTokenCounter()

                assert.equal(tokenCounter.toString(), "1")
                assert.equal(tokenURI, await basicNft.TOKEN_URI())
            })
            it("Show the correct  owner of an NFT", async function () {
                const deployerAddress = deployer.address;
                const owner = await basicNft.ownerOf("1")
                assert.equal(owner, deployerAddress)
            })
        })
    })

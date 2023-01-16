//we import this file during testing in test dir
//here we store cutom price feed address of diffeent chains on CHAINLINK
//here we also define our development chains 

const { ethers } = require("hardhat")

const networkConfig = {
    31337: {
        name: "localhost",
        gasLane: '0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15',
        callbackGasLimit: '500000',
        interval: '30',
        mintFee: ethers.utils.parseEther('0.01'),
    },
    // Price Feed Address, values can be obtained at https://docs.chain.link/docs/reference-contracts
    5: {
        name: "goerli",
        ethUsdPriceFeed: "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e",
        vrfCoordinatorV2: '0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D',
        gasLane: '0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15',
        subscriptionId: '6082',
        callbackGasLimit: '500000',
        interval: '30',
        mintFee: ethers.utils.parseEther('0.01'),

    },
    //here we can define "ethUsdPriceFeed" for different chains
}
const DECIMALS = "18"
const INITIAL_PRICE = "200000000000000000000"
const developmentChains = ["hardhat", "localhost"]

module.exports = {
    networkConfig,
    developmentChains,
    DECIMALS,
    INITIAL_PRICE,
}

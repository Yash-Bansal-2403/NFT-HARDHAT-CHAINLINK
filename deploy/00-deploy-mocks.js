const { network } = require("hardhat")
//network will be used to extract chainId using network.config.chainId

const { DECIMALS, INITIAL_PRICE } = require("../helper-hardhat-config")// inputs to MockV3Aggregator

const BASE_FEE = "250000000000000000" // input to VRFCoordinatorV2Mock
const GAS_PRICE_LINK = 1e9// input to VRFCoordinatorV2Mock

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId
    // If we are on a local development network, we need to deploy mocks!
    if (chainId == 31337) {
        log("Local network detected! Deploying mocks...")
        await deploy("VRFCoordinatorV2Mock", {
            from: deployer,
            log: true,
            args: [BASE_FEE, GAS_PRICE_LINK],
        })
        await deploy("MockV3Aggregator", {
            from: deployer,
            log: true,
            args: [DECIMALS, INITIAL_PRICE],
        })

        log("Mocks Deployed!")
        log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    }
}
module.exports.tags = ["all", "mocks", "main"]

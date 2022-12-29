import { DeployFunction } from 'hardhat-deploy/dist/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { ethers, network } from 'hardhat'
import { networkConfig } from '../helper-config'
import verify from '../utils/verify'

const deploySmartRent: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { getNamedAccounts, deployments } = hre

    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    const chainId = network.config.chainId!

    const rentPrice = networkConfig[chainId].rentPrice
    const numberOfMonths = networkConfig[chainId].numberOfMonths

    let MANAGER_ADDRESS

    if (chainId != 31337) {
        MANAGER_ADDRESS = process.env.MANAGER_ADDRESS! //Unlockit Account
    } else {
        const accounts = await ethers.getSigners()
        MANAGER_ADDRESS = accounts[1].address
    }

    const args = [MANAGER_ADDRESS, rentPrice, numberOfMonths]

    const smartRent = await deploy('smartRent', {
        from: deployer,
        log: true,
        args: args,
        waitConfirmations: networkConfig[chainId].blockConfirmations || 1,
    })

    if (chainId != 31337 && process.env.ETHERSCAN_API_KEY) {
        log('Verifying contract...')
        await verify(smartRent.address, args)
    }
}

export default deploySmartRent
deploySmartRent.tags = ['all', 'rent']

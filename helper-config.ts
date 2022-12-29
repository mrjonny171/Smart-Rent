import { BigNumber } from 'ethers'
import { ethers } from 'hardhat'

export interface networkConfigItem {
    name?: string
    blockConfirmations?: number
    rentPrice?: BigNumber
    numberOfMonths?: number
}

export interface networkConfigInfo {
    [key: string]: networkConfigItem
}

export const networkConfig: networkConfigInfo = {
    5: {
        name: 'goerli',
        blockConfirmations: 6,
        rentPrice: ethers.utils.parseEther('0.1'),
        numberOfMonths: 12,
    },
    137: {
        name: 'polygon',
        blockConfirmations: 6,
        rentPrice: ethers.utils.parseEther('0.1'),
        numberOfMonths: 12,
    },
    31337: {
        rentPrice: ethers.utils.parseEther('0.1'),
        numberOfMonths: 12,
    },
}

export const developmentChains = ['hardhat', 'localhost']

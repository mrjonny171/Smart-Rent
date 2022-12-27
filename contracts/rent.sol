// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

error InvalidFunder();
error InvalidManager();
error InsuficientFunds();

contract rent {
    //Owner of the house
    address private s_owner;

    //Starting date of the rent contract
    //uint256 private i_startingDate; ?

    //Unlockit Address
    address private immutable i_manager;

    uint256 private constant UNLOCKIT_FEE = 1;

    //Tenant, the one who is paying the contract
    address private s_tenant;

    //Contract Balance
    uint256 private s_balance;

    //Rent Price
    uint256 private s_rentPrice;

    constructor(address manager, uint256 rentPrice) {
        s_owner = msg.sender;
        i_manager = manager;
        s_rentPrice = rentPrice;
    }

    /**
     * Funds the contract with a certain amount of eth
     */
    function fund() public payable {
        if (msg.sender != s_tenant) {
            revert InvalidFunder();
        }
        s_balance += msg.value;
    }

    function sendPayment() public payable {
        if (msg.sender != i_manager) {
            revert InvalidManager();
        }

        if (s_balance < s_rentPrice) {
            revert InsuficientFunds();
        }

        bool success;

        uint256 ownerPayment = (s_rentPrice * (100 - UNLOCKIT_FEE)) / 100;
        uint256 feePayment = (s_rentPrice * UNLOCKIT_FEE) / 100;

        (success, ) = s_owner.call{value: ownerPayment}('');
        require(success, 'Payment Failed');

        (success, ) = i_manager.call{value: feePayment}('');
        require(success, 'Payment Failed');
    }

    function getManager() public view returns (address) {
        return i_manager;
    }

    function getOwner() public view returns (address) {
        return s_owner;
    }

    function getBalance() public view returns (uint256) {
        return s_balance;
    }

    function getRentPrice() public view returns (uint256) {
        return s_rentPrice;
    }
}

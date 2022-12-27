// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

error InvalidFunder();
error InvalidManager();
error InsuficientFunds();
error NoAuthorization();
error OwnerNoExtension();
error TenantNoExtension();
error ContractExpired();
error ContractOccupied();

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

    //Rent  Price
    uint256 private s_rentPrice;

    //Duration of the contract
    uint256 private s_numberOfMonths;

    uint256 private s_paidMonths;

    // Address => New Duration => True / False
    mapping(address => mapping(uint256 => bool)) private s_extendAuthorizations;

    constructor(address manager, uint256 rentPrice, uint256 numberOfMonths) {
        s_owner = msg.sender;
        i_manager = manager;
        s_rentPrice = rentPrice;
        s_numberOfMonths = numberOfMonths;
        s_paidMonths = 0;
    }

    function beTenant() public {
        if (s_tenant != address(0)) {
            revert ContractOccupied();
        }

        s_tenant = msg.sender;
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

    //Pay the corresponding Value to the owner and the unlockit Fee
    function sendPayment() public payable {
        if (msg.sender != i_manager) {
            revert InvalidManager();
        }

        if (s_balance < s_rentPrice) {
            revert InsuficientFunds();
        }

        if (s_paidMonths == s_numberOfMonths) {
            revert ContractExpired();
        }

        bool success;

        uint256 ownerPayment = (s_rentPrice * (100 - UNLOCKIT_FEE)) / 100;
        uint256 feePayment = (s_rentPrice * UNLOCKIT_FEE) / 100;

        (success, ) = s_owner.call{value: ownerPayment}('');
        require(success, 'Payment Failed');

        (success, ) = i_manager.call{value: feePayment}('');
        require(success, 'Payment Failed');

        s_paidMonths++;
        s_balance -= s_rentPrice;
    }

    /**
     * Function to request authorization from tenant and owner to extend the contract duration
     */
    function increaseContractDuration(uint256 increasedDuration) public {
        if (msg.sender == s_owner) {
            s_extendAuthorizations[s_owner][increasedDuration] = true;
        }

        if (msg.sender == s_tenant) {
            s_extendAuthorizations[s_tenant][increasedDuration] = true;
        }

        if (msg.sender == i_manager) {
            if (!s_extendAuthorizations[s_owner][increasedDuration]) {
                revert OwnerNoExtension();
            }

            if (!s_extendAuthorizations[s_tenant][increasedDuration]) {
                revert TenantNoExtension();
            }

            s_extendAuthorizations[s_owner][increasedDuration] = false;
            s_extendAuthorizations[s_tenant][increasedDuration] = false;

            s_numberOfMonths += increasedDuration;
        } else {
            revert NoAuthorization();
        }
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

    function getUnlockitFee() public pure returns (uint256) {
        return UNLOCKIT_FEE;
    }
}

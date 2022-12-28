// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

error InvalidFunder();
error InvalidManager();
error InvalidOwner();

error InsuficientFunds();
error NoAuthorization();
error OwnerNoExtension();
error TenantNoExtension();
error ContractExpired();
error ContractOccupied();
error NoCandidates();

contract rent {
    //Struct that defines the values that our contract will be developed in
    struct candidate {
        address account;
        uint256 revenue;
    }

    //Owner of the house
    address private s_owner;

    //Unlockit Address
    address private immutable i_manager;

    // Possible tenants
    candidate[] private s_candidates;
    uint256 private nPossibleTenants;

    uint256 private constant UNLOCKIT_FEE = 1;

    //Tenant, the one who is paying the contract
    address private s_chosenTenant;

    //Contract Balance
    uint256 private s_balance;

    //Rent  Price
    uint256 private s_rentPrice;

    //Duration of the contract
    uint256 private s_numberOfMonths;

    uint256 private s_paidMonths;

    // Address => New Duration => True / False
    mapping(address => mapping(uint256 => bool)) private s_extendAuthorizations;

    /**
     * @dev Owner is only responsible for creating the initial
     * state of the renting contract
     */
    constructor(address manager, uint256 rentPrice, uint256 numberOfMonths) {
        s_owner = msg.sender;
        i_manager = manager;
        s_rentPrice = rentPrice;
        s_numberOfMonths = numberOfMonths;
        s_paidMonths = 0;
    }

    function chooseTenant() public {
        if (msg.sender != s_owner) {
            revert InvalidOwner();
        }

        if (nPossibleTenants == 0) {
            revert NoCandidates();
        }

        candidate memory bestTenant = s_candidates[0];

        for (uint i = 1; i < nPossibleTenants; i++) {
            if (s_candidates[i].revenue > bestTenant.revenue) {
                bestTenant = s_candidates[i];
            }
        }

        s_chosenTenant = bestTenant.account;
    }

    /**
     * @dev Manager Functions
     */

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
     * @dev Tenant Functions
     */

    function applyForRentContract(
        uint256 revenue
    ) public /* Argumentos Estilo numeros do IRS, etc */ {
        s_candidates.push(candidate(msg.sender, revenue));
        nPossibleTenants++;
    }

    /**
     * Funds the contract with a certain amount of eth
     */
    function fund() public payable {
        if (msg.sender != s_chosenTenant) {
            revert InvalidFunder();
        }
        s_balance += msg.value;
    }

    /**
     * Function to request authorization from tenant and owner to extend the contract duration
     */

    //Refactor
    function increaseContractDuration(uint256 increasedDuration) public {
        if (msg.sender == s_owner) {
            s_extendAuthorizations[s_owner][increasedDuration] = true;
        }

        if (msg.sender == s_chosenTenant) {
            s_extendAuthorizations[s_chosenTenant][increasedDuration] = true;
        }

        if (msg.sender == i_manager) {
            if (!s_extendAuthorizations[s_owner][increasedDuration]) {
                revert OwnerNoExtension();
            }

            if (!s_extendAuthorizations[s_chosenTenant][increasedDuration]) {
                revert TenantNoExtension();
            }

            s_extendAuthorizations[s_owner][increasedDuration] = false;
            s_extendAuthorizations[s_chosenTenant][increasedDuration] = false;

            s_numberOfMonths += increasedDuration;
        } else {
            revert NoAuthorization();
        }
    }

    /**
     * @dev Getters
     */

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

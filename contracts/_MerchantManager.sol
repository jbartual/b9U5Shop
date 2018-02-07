pragma solidity ^0.4.4;

/*

Last Update: 2018-02-06
Version: 2.0

Super contract to manage Merchants that sell products in a shop.
Product are managed in the Products Manager contract.

Modifiers:
- onlyMerchants

CORE functions:
- Constructor
- addMerchant
- removeMerchant
- addMerchantSale
- removeMerchantSale
- merchantWithdrawAllBalance

SUPPORT functions
- isMerchant
- getInfoMerchantSales

*/

import "./_Stoppable.sol";

contract MerchantManager is Stoppable {
    mapping (address => bool) private merchants; //key = merchant address
    mapping (address => uint) private merchantSales; //account merchant's sales

    modifier onlyMerchants () { require(merchants[msg.sender]); _; }
    
// CORE functions

        event LogMerchantManagerNew (address _sender);
        // Constrcutor
    function MerchantManager()
        public
    {
        merchants[msg.sender] = true; //by default the first merchant is root
        LogMerchantManagerNew (msg.sender);
    }

        event LogMerchantManagerAddMerchant (address _sender, address _merchant);
        // To add new merchants
    function addMerchant (address _merchant)
        internal
        onlyIfRunning
        returns (bool _success)
    {
        require (_merchant != 0);

        merchants[_merchant] = true;
        
        LogMerchantManagerAddMerchant (msg.sender,  _merchant);
        return true;
    }

        event LogMerchantManagerRemoveMerchant (address _sender, address _merchant);
        // To remove merchants
    function removeMerchant (address _merchant)
        internal
        onlyIfRunning
        returns (bool _success)
    {
        require (_merchant != 0);
        require (merchants[_merchant]); //require a valid merchant
        require (merchantSales[msg.sender] == 0); //require all Merchant's sales balance to have been already transfered to the Merchant

        delete merchants[_merchant];

        LogMerchantManagerRemoveMerchant (msg.sender,  _merchant);
        return true;
    }

        event LogMerchantManagerAddMerchantSale (address _sender, address _merchant, uint _amount);
        // To add a sale amount to a merchant. This increases a Merchant's balance
    function addMerchantSale (address _merchant, uint _amount)
        internal
        onlyIfRunning
        returns (bool _success)
    {
        require (_merchant != 0);
        require (_amount > 0);

        merchantSales[_merchant] += _amount; //add the purchase amount to the merchant
        LogMerchantManagerAddMerchantSale (msg.sender, _merchant, _amount);
        return true;
    }
        event LogMerchantManagerRemoveMerchantSale (address _sender, address _merchant, uint _amount);
        // In case of a refund, this function shall be executed to adjust Merchant's balance
    function removeMerchantSale (address _merchant, uint _amount)
        internal
        onlyIfRunning
        returns (bool _success)
    {
        require (_merchant != 0);
        require (_amount > 0);

        if (merchantSales[_merchant] - _amount > 0) // check that the end balance stay positive
            merchantSales[_merchant] -= _amount;
        else delete merchantSales[_merchant];

        LogMerchantManagerRemoveMerchantSale (msg.sender, _merchant, _amount);
        return true;        
    }

        event LogMerchantManagerMerchantWithdrawAllBalance (address _sender, uint _transferAmount);
    // Merchants withdraw sales funds executing this function
    // The contract will not send funds to any account, instead merchants shall withdraw funds from the contract themselves
    function merchantWithdrawAllBalance ()
        onlyMerchants
        onlyIfRunning
        internal
        returns (bool _success)
    {
        require(merchantSales[msg.sender] > 0); //require positive merchant balance | prevents re-entry

        uint balance = merchantSales[msg.sender];
        delete merchantSales[msg.sender]; //optimistic accounting

        msg.sender.transfer(balance);

        LogMerchantManagerMerchantWithdrawAllBalance (msg.sender, balance);
        return true;
    }

// SUPPORT functions

    function isMerchant (address _merchant)
        public
        constant
        returns (bool _is)
    {
        require (_merchant != 0);
        
        return (merchants[_merchant]);
    }

    function getInfoMerchantSales (address _merchant)
        public
        constant
        returns (uint _balance)
    {
        require (_merchant != 0);

        return (merchantSales[_merchant]);
    }    

}
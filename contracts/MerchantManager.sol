pragma solidity ^0.4.4;

import "./MyShared/Stoppable.sol";

contract MerchantManager is Stoppable {
    mapping (address => bool) private merchants; //key = merchant address
    mapping (address => uint256) private merchantSales; //account merchant's sales
    
        event LogMerchantManagerNew (address _sender);
    // Constrcutor
    function MerchantManager()
        public
    {
        merchants[msg.sender] = true; //by default the first merchant is root
        LogMerchantManagerNew (msg.sender);
    }

    modifier onlyMerchants () { require(merchants[msg.sender]); _; }

    function isMerchant (address _merchant)
        public
        constant
        returns (bool _is)
    {
        return (merchants[_merchant]);
    }

    function getMerchantSalesBalance (address _merchant)
        public
        constant
        returns (uint256 _balance)
    {
        return (merchantSales[_merchant]);
    }    

        event LogMerchantManager_addMerchant (address _sender, address _merchant);
    // To add new merchants
    function _addMerchant (address _merchant)
        internal
        onlyIfRunning
        returns (bool _success)
    {
        require (_merchant != 0);

        merchants[_merchant] = true;
        
        LogMerchantManager_addMerchant (msg.sender,  _merchant);
        return true;
    }

        event LogMerchantManager_removeMerchant (address _sender, address _merchant);
    // To remove merchants
    function _removeMerchant (address _merchant)
        internal
        onlyIfRunning
        returns (bool _success)
    {
        require(merchants[_merchant]);

        delete merchants[_merchant];

        LogMerchantManager_removeMerchant (msg.sender,  _merchant);
        return true;
    }

        event LogMerchantManager_addMerchantSale (address indexed _sender, address indexed _merchant, uint256 _amount);
    // To add a sale amount to a merchant. This increases a merchant sales balance
    function _addMerchantSale (address _merchant, uint256 _amount)
        internal
        onlyIfRunning
        returns (bool _success)
    {
        merchantSales[_merchant] += _amount; //add the purchase amount to the merchant
        LogMerchantManager_addMerchantSale (msg.sender, _merchant, _amount);
        return true;
    }

        event LogMerchantManager_withdrawAllBalance (address indexed _sender, uint256 _transferAmount);
    // Merchants withdraw sales funds executing this function
    // The contract will not send funds to any account, instead merchants shall withdraw funds from the contract themselves
    function _withdrawAllBalance ()
        onlyMerchants
        onlyIfRunning
        internal
        returns (bool _success)
    {
        require(merchantSales[msg.sender] > 0); //require positive merchant balance | prevents re-entry

        uint256 balance = merchantSales[msg.sender];
        merchantSales[msg.sender] = 0; //optimistic accounting

        msg.sender.transfer(balance);

        LogMerchantManager_withdrawAllBalance (msg.sender, balance);
        return true;
    }
    
}
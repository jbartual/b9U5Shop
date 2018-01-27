pragma solidity ^0.4.4;

import "./MyShared/Stoppable.sol";

contract ProductManager is Stoppable {
    struct Product {
        uint256 unitPrice;
        uint stock;
    }
    mapping (address => mapping (bytes32 => Product)) public products; //keys = merchant address, productId

    mapping (address => bool) private merchants; //key = merchant address

        event LogProductManagerNew (address _sender);
    //Constructor
    function ProductManager() 
        public
    {
        merchants[msg.sender] = true; //by default the first merchant is root

        LogProductManagerNew(msg.sender);
    }
    
    modifier onlyMerchants () { require(merchants[msg.sender]); _; }

// ---- Merchant functions ----
        event LogShopAddMerchant (address _sender, address _merchant);
    // To add new merchants
    function _addMerchant (address _merchant)
        internal
        returns (bool _success)
    {
        merchants[_merchant] = true;
        LogShopAddMerchant (msg.sender,  _merchant);
        return true;
    }

        event LogShopRemoveMerchant (address _sender, address _merchant);
    // To remove merchants
    function _removeMerchant (address _merchant)
        internal
        returns (bool _success)
    {
        require(merchants[_merchant]);

        delete merchants[_merchant];
        LogShopRemoveMerchant (msg.sender,  _merchant);
        return true;
    }

    function isMerchant (address _merchant)
        public
        constant
        returns (bool _is)
    {
        return (merchants[_merchant]);
    }
    
// ---- Product functions ----
    function getProductInfo (address _merchant, bytes32 _productId)
        public
        constant
        returns (uint _unitPrice, uint _stock)
    {
        return (products[_merchant][_productId].unitPrice, products[_merchant][_productId].stock);
    }

        event LogProductManagerAddProduct (address _sender, bytes32 _productId, uint256 _unitPrice, uint _stock);
    // To add a new product
    function addProduct (bytes32 _productId, uint256 _unitPrice, uint _stock)
        onlyMerchants
        onlyIfRunning
        public
        returns (bool _success)
    {
        products[msg.sender][_productId].unitPrice = _unitPrice;
        products[msg.sender][_productId].stock += _stock;

        LogProductManagerAddProduct (msg.sender, _productId, _unitPrice, _stock);
        return true;
    }

        event LogProductManagerRemoveProduct (address _sender, bytes32 _productId);
    // To remove a product
    function removeProduct (bytes32 _productId)
        onlyMerchants
        onlyIfRunning
        public
        returns (bool _success)
    {
        delete products[msg.sender][_productId];

        LogProductManagerRemoveProduct (msg.sender, _productId);
        return true;
    }

}
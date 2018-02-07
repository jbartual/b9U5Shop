pragma solidity ^0.4.4;

/*

Last Update: 2018-02-06
Version: 2.0

Super contract to manage Merchants that sell products in a shop.
Product are managed in the Products Manager contract.

CORE functions:
- Constructor
- addProduct
- removeProduct

SUPPORT functions
- getInfoProduct

*/

import "./_MerchantManager.sol";

contract ProductManager is MerchantManager {
    struct Product {
        uint unitPrice;
        uint stock;
    }
    mapping (address => mapping (bytes32 => Product)) public products; //merchant address => productID => Product

// CORE functions

        event LogProductManagerNew (address _sender);
        //Constructor
    function ProductManager() 
        public
    {
        LogProductManagerNew(msg.sender);
    }
    
        event LogProductManagerAddProduct (address _sender, bytes32 _productID, uint _unitPrice, uint _stock);
        // To add a new product
    function addProduct (bytes32 _productID, uint _unitPrice, uint _stock)
        onlyMerchants
        onlyIfRunning
        internal
        returns (bool _success)
    {
        require (_productID != 0);

        products[msg.sender][_productID].unitPrice = _unitPrice;
        products[msg.sender][_productID].stock += _stock;

        LogProductManagerAddProduct (msg.sender, _productID, _unitPrice, _stock);
        return true;
    }

        event LogProductManagerRemoveProduct (address _sender, bytes32 _productID);
        // To remove a product
    function removeProduct (bytes32 _productID)
        onlyMerchants
        onlyIfRunning
        internal
        returns (bool _success)
    {
        require (_productID != 0);
        
        delete products[msg.sender][_productID];

        LogProductManagerRemoveProduct (msg.sender, _productID);
        return true;
    }

// SUPPORT functions

    function getInfoProduct (address _merchant, bytes32 _productID)
        constant
        public
        returns (uint _unitPrice, uint _stock)
    {
        require (_merchant != 0);
        require (_productID != 0);

        return (products[_merchant][_productID].unitPrice, products[_merchant][_productID].stock);
    }
}
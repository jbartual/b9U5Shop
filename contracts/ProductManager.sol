pragma solidity ^0.4.4;

import "./MerchantManager.sol";

/*
Product require of a Merchant as their ID is the same as the ID in the Merchant database for simplicity
*/

contract ProductManager is MerchantManager {
    struct Product {
        uint256 unitPrice;
        uint stock;
    }
    mapping (address => mapping (bytes32 => Product)) public products; //keys = merchant address, productId

        event LogProductManagerNew (address _sender);
    //Constructor
    function ProductManager() 
        public
    {
        LogProductManagerNew(msg.sender);
    }
    
    function getProductInfo (address _merchant, bytes32 _productId)
        public
        constant
        returns (uint _unitPrice, uint _stock)
    {
        return (products[_merchant][_productId].unitPrice, products[_merchant][_productId].stock);
    }
    
        event LogProductManager_addProduct (address _sender, bytes32 _productId, uint256 _unitPrice, uint _stock);
    // To add a new product
    function _addProduct (bytes32 _productId, uint256 _unitPrice, uint _stock)
        onlyMerchants
        onlyIfRunning
        internal
        returns (bool _success)
    {
        products[msg.sender][_productId].unitPrice = _unitPrice;
        products[msg.sender][_productId].stock += _stock;

        LogProductManager_addProduct (msg.sender, _productId, _unitPrice, _stock);
        return true;
    }

        event LogProductManager_removeProduct (address _sender, bytes32 _productId);
    // To remove a product
    function _removeProduct (bytes32 _productId)
        onlyMerchants
        onlyIfRunning
        internal
        returns (bool _success)
    {
        delete products[msg.sender][_productId];

        LogProductManager_removeProduct (msg.sender, _productId);
        return true;
    }

}
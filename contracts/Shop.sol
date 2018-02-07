pragma solidity ^0.4.4;

/*

Last update: 2018-02-07
Version: 2.1

A shopfront
The project will start as a database whereby:
- as an shopOwner, you can add products, which consist of an id, a price and a stock.
- as a regular user you can buy 1 of the products.
- as the owner you can make payments or withdraw value from the contract.

Eventually, you will refactor it to include:
- ability to remove products.
- co-purchase by different people.
- add merchants akin to what Amazon has become.
- add the ability to pay with a third-party token.

Workflow:
- Shop Owner:
    - Creates the shop
    - Add/remove merchants

- Merchant:
    - Add/remove products to the shop
    - Can withdraw sales balance at any time

- Customer:
    - Either purchases a product on his own or starts a shared purchase
        - If he has the hash-ticket he can contribute to a share purchase

Modifiers:
- onlyShopOwners

CORE functions:
- purchaseProduct
- purchaseSharedProduct
- updatePurchaseSharedProduct
- registerPurchase

ADMIN functions:
- addShopOwner
- removeShopOwner
- shopAddMerchant
- shopRemoveMerchant
- shopAddProduct
- shopRemoveProduct
- shopMerchantWithdrawAllBalance

SUPPORT functions:
- isShopOwner

*/

import "./_FundsManager.sol";
import "./_ProductManager.sol";

contract Shop is FundsManager, ProductManager {
    mapping (address => bool) private shopOwners;

    struct Purchase {
        address[] buyers; //a purchase could be shared by more than one buyer
        address merchant;
        bytes32 productID;
        uint units; //units sold
        uint total; //total sale amount
        uint paid;  //total paid, specially relevant in case of a shared purchase
    }
    mapping (bytes32 => Purchase) private purchases; //transaction Hash => Purchase

    uint purchaseCounter;

    modifier onlyShopOwners () { require(shopOwners[msg.sender]); _; }

// CORE functions

        event LogShopNew (address _sender);
        //Constructor
    function Shop ()
        public
    {
        shopOwners[msg.sender] = true; //add owner to shopOwners

        LogShopNew (msg.sender);
    }

        event LogShopPurchaseProduct (address _sender, address _merchant, bytes32 _productID, uint _units, uint _unitPrice, uint _total, uint _amount, bytes32 _hashTicket);
        // The sale amount will be credited to the merchant
    function purchaseProduct (address _merchant, bytes32 _productID, uint _units)
        onlyIfRunning
        public
        payable
        returns (bytes32 _hashTicket)
    {
        require (_merchant != 0);
        require (_productID != 0);
        require (_units > 0);
        require (msg.value > 0);

        Product storage product = products[_merchant][_productID]; //get a reference to the product in the storage

        require (product.stock >= _units); // check stock

        uint total = product.unitPrice * _units; // calculate total required balance
        require (msg.value == total); //the buyer sends the right value amount

        bytes32 hashTicket = newHashTicket();
        registerPurchase (hashTicket, _merchant, _productID, _units, total, msg.value); //register the purchase

        depositFunds (hashTicket); //account funds deposit
        addMerchantSale(_merchant, total); //account the purchase to the merchant
        spendFunds (hashTicket, total); //deduct total from buyer
        //here we could call a delivery function to send the products to the buyer

        LogShopPurchaseProduct (msg.sender, _merchant, _productID, _units, product.unitPrice, total, msg.value, hashTicket);
        return hashTicket;
    }

        event LogShopPurchaseSharedProduct (address _sender, address _merchant, bytes32 _productID, uint _units, uint _unitPrice, uint _total, uint _amount, bytes32 _hashTicket);
        // To be executed by the fist buyer of a shared purchase
    function purchaseSharedProduct (address _merchant, bytes32 _productID, uint _units)
        onlyIfRunning
        public
        payable
        returns (bytes32 _hashTicket)
    {
        require (_units > 0);
        require (_productID != 0);
        
        Product storage product = products[_merchant][_productID]; //get a reference to the product in the storage

        require (product.stock >= _units); // check stock
        uint total = product.unitPrice * _units; // calculate total required balance
        require (msg.value < total); //require to start a shared purchase with less amount than the purchase total

        bytes32 hashTicket = newHashTicket();
        registerPurchase (hashTicket, _merchant, _productID, _units, total, msg.value); //register the purchase

        depositFunds (hashTicket); //account funds deposit
        spendFunds (hashTicket, msg.value); //deduct total from buyer
        //do not account the purchase to the merchant as the sale is not fully paid
        
        LogShopPurchaseSharedProduct (msg.sender, _merchant, _productID, _units, product.unitPrice, total, msg.value, hashTicket);
        return hashTicket;
    }

        event LogShopUpdatePurchaseSharedProduct (address _sender, bytes32 _hashTicket, uint _amount, uint _paid, uint _remainingTotal);
        // co-purchase by different buyers
        // If the purchase is totally paid off the sale will be credited to the merchant
    function updatePurchaseSharedProduct (bytes32 _hashTicket)
        onlyIfRunning
        public
        payable
        returns (uint _remainingTotal)
    {
        require (_hashTicket != 0);
        require (msg.value > 0);

        Purchase storage purchase = purchases[_hashTicket];

        require (purchase.total > purchase.paid); //ensure that there is amount left to be paid

        uint toPay;

        if (msg.value > (purchase.total - purchase.paid)) // sending more funds than remaining total
            toPay = msg.value - (purchase.total - purchase.paid);
        else
            toPay = msg.value;

        purchase.buyers.push(msg.sender);
        purchase.paid += toPay;

        uint remainingTotal;

        if (purchase.paid == purchase.total) //if it is completely paid then
        {
            addMerchantSale(purchase.merchant, purchase.total); //account the purchase to the merchant
            // here we could call a delivery function to send the products to the buyer
            // remainingTotal = 0; // There is no left amount to be paid. No need for this assignment as by default is 0
        }
        else
        {
            remainingTotal = purchase.total - purchase.paid;
        }

        depositFunds (_hashTicket); //account funds deposit
        spendFunds (_hashTicket, toPay); //deduct amount from buyer

        LogShopUpdatePurchaseSharedProduct (msg.sender, _hashTicket, msg.value, toPay, remainingTotal);
        return remainingTotal;
    }

        event LogShopRegisterPurchase (address indexed _sender, address _merchant, bytes32 _productID, uint _units, uint _total, uint _paid, bytes32 _hashTicket);
        //Register the purchase in the struct
    function registerPurchase (bytes32 _hashTicket, address _merchant, bytes32 _productID, uint _units, uint _total, uint _paid)
        onlyIfRunning
        private
        returns (bool _success)
    {
        purchases[_hashTicket].buyers.push(msg.sender); //register purchase

        Purchase storage purchase = purchases[_hashTicket];
            purchase.merchant = _merchant;
            purchase.productID = _productID;
            purchase.units = _units;
            purchase.total = _total;
            purchase.paid += _paid;
        
        Product storage product = products[_merchant][_productID];
        
        if (product.stock == _units)
            product.stock = 0;
        else
            product.stock -= _units; //update stock

        LogShopRegisterPurchase (msg.sender, _merchant, _productID, _units, _total, _paid, _hashTicket);
        return true;
    }    

// ADMIN functions

        event LogShopAddShopOwner (address _sender, address _shopOwner);
        // To add a new admin
    function addShopOwner (address _shopOwner)
        onlyOwner
        public
        returns (bool _success)
    {
        require (_shopOwner != 0);

        shopOwners[_shopOwner] = true;

        LogShopAddShopOwner (msg.sender, _shopOwner);
        return true;
    }

        event LogShopRemoveShopOwner (address _sender, address _shopOwner);
    // Remove an admin. Owner cannot be removed
    function removeShopOwner (address _shopOwner)
        onlyOwner
        public
        returns (bool _success)
    {
        require (_shopOwner != getInfoOwner()); //owner cannot be removed

        delete shopOwners[_shopOwner];

        LogShopRemoveShopOwner (msg.sender, _shopOwner);
        return true;
    }

    // Expose internal MerchantManager function
    function shopAddMerchant (address _merchant)
        onlyShopOwners
        public
        returns (bool _success)
    {
        require (!shopOwners[_merchant]); // A merchant cannot be an shopOwner

        return addMerchant(_merchant); //call the internal function in MerchantManager
    }

    // Expose internal MerchantManager function
    function shopRemoveMerchant (address _merchant)
        onlyShopOwners
        public
        returns (bool _success)
    {
        require (_merchant != getInfoOwner()); //owner cannot be removed
        
        return removeMerchant(_merchant); //call the internal function in MerchantManager
    }

    // Expose internal ProductManager function
    function shopAddProduct (bytes32 _productID, uint _unitPrice, uint _stock)
        public
        returns (bool _success)
    {
        return addProduct (_productID, _unitPrice, _stock);
    }

    // Expose internal ProductManager function
    function shopRemoveProduct (bytes32 _productID)
        public
        returns (bool _success)
    {
        return removeProduct (_productID);
    }

    // Expose internal MerchantManager function
    function shopMerchantWithdrawAllBalance ()
        public
        returns (bool _success)
    {
        require(msg.sender != getInfoOwner()); //the owner cannot withdraw his own funds
        
        return merchantWithdrawAllBalance ();
    }

// SUPPORT functions

    function isShopOwner (address _shopOwner)
        constant
        public
        returns (bool _isIndeed)
    {
        return (shopOwners[_shopOwner]);
    }
}
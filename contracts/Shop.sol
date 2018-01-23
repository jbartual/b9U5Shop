pragma solidity ^0.4.4;

import "./MyShared/Funded.sol";

/*
A shopfront
The project will start as a database whereby:
- as an administrator, you can add products, which consist of an id, a price and a stock.
- as a regular user you can buy 1 of the products.
- as the owner you can make payments or withdraw value from the contract.

Eventually, you will refactor it to include:
- ability to remove products.
- co-purchase by different people.
- add merchants akin to what Amazon has become.
- add the ability to pay with a third-party token.
*/

contract Shop is Funded {

    address private root; //Root administrator
    mapping (address => bool) private administrators;

    mapping (address => bool) private merchants; //key = merchant address
    mapping (address => uint256) private merchantsSales; //account merchant's sales

    struct Product {
        address merchant;
        uint256 unitPrice;
        uint stock;
    }
    mapping (address => mapping (bytes32 => Product)) public products; //keys = merchant address, productId

    struct Purchase {
        address merchant;
        bytes32 productId;
        uint units;
        uint256 unitPrice;
        uint256 total;
    }
    mapping (address => Purchase[]) public purchases; //key = buyer address

    event LogShopNew (address _sender);
    //Constructor
    function Shop ()
        Funded (msg.sender)
        public
    {
        root = msg.sender;
        administrators[msg.sender] = true; //add root to the administrators
        merchants[msg.sender] = true; //by default the first merchant is root

        LogShopNew (msg.sender);
    }

    modifier onlyRoot () { require(msg.sender == root); _; }
    modifier onlyAdminstrators () { require(administrators[msg.sender]); _; }
    modifier onlyMerchants () { require(merchants[msg.sender]); _; }

    function getProductInfo (address _merchant, bytes32 _productId)
        public
        constant
        returns (uint _unitPrice, uint _stock)
    {
        return (products[_merchant][_productId].unitPrice, products[_merchant][_productId].stock);
    }

    function getMerchantInfo (address _merchant)
        public
        constant
        returns (uint256 _balance)
    {
        return (merchantsSales[_merchant]);
    }

    event LogShopAddAdministrator (address _sender, address _administrator);
    // To add a new admin
    function addAdministrator (address _administrator)
        onlyRoot
        public
        returns (bool _success)
    {
        require (_administrator != 0);
        administrators[_administrator] = true;
        LogShopAddAdministrator (msg.sender, _administrator);
        return true;
    }

    event LogShopRemoveAdministrator (address _sender, address _administrator);
    // Remove an admin. Root cannot be removed
    function removeAdministrator (address _administrator)
        onlyRoot
        public
        returns (bool _success)
    {
        require (_administrator != root); //Root cannot be removeAdministrator
        administrators[_administrator] = false;
        LogShopRemoveAdministrator (msg.sender, _administrator);
        return true;
    }

    function isAdministrator (address _administrator)
        public
        constant
        returns (bool _is)
    {
        return (administrators[_administrator]);
    }

    event LogShopAddMerchant (address _sender, address _merchant);
    // To add merchants. Only administrators.
    // A merchan canot be an administrator
    function addMerchant (address _merchant)
        onlyAdminstrators
        public
        returns (bool _success)
    {
        require(!administrators[_merchant]);

        merchants[_merchant] = true;
        LogShopAddMerchant (msg.sender,  _merchant);
        return true;
    }

    event LogShopRemoveMerchant (address _sender, address _merchant);
    // Remove merchants. Only administrators
    function removeMerchant (address _merchant)
        onlyAdminstrators
        public
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

    event LogShopAddShopProduct (address _sender, bytes32 _id, uint256 _unitPrice, uint _stock);
    // Add a product. Only admins
    // This is the default method to add products. It assigns them to root as the merchant
    function addShopProduct (bytes32 _productId, uint256 _unitPrice, uint _stock)
        onlyAdminstrators
        public
        returns (bool _success)
    {
        addProduct (root, _productId, _unitPrice, _stock);
        LogShopAddShopProduct (msg.sender, _productId, _unitPrice, _stock);
        return true;
    }

    event LogShopRemoveShopProduct (address _sender, bytes32 _productId);
    // Remove a product. Only admins
    function removeShopProduct (bytes32 _productId)
        onlyAdminstrators
        public
        returns (bool _success)
    {
        removeProduct (root, _productId);
        LogShopRemoveShopProduct (msg.sender, _productId);
        return true;
    }

    event LogShopAddMerchantProduct (address _merchant, bytes32 _productId, uint256 _unitPrice, uint _stock);
    // A merchant adds a new product to the contract
    function addMerchantProduct (bytes32 _productId, uint256 _unitPrice, uint _stock)
        onlyMerchants
        public
        returns (bool _success)
    {
        addProduct (msg.sender, _productId, _unitPrice, _stock);
        LogShopAddMerchantProduct (msg.sender, _productId, _unitPrice, _stock);
        return true;
    }

    event LogShopRemoveMerchantProduct (address _sender, bytes32 _productId);
    // Remove a product. Only admins
    function removeMerchantProduct (bytes32 _productId)
        onlyMerchants
        public
        returns (bool _success)
    {
        removeProduct (msg.sender, _productId);
        LogShopRemoveMerchantProduct (msg.sender, _productId);
        return true;
    }

    // PRIVATE
    // To add a new product
    function addProduct (address _merchant, bytes32 _productId, uint256 _unitPrice, uint _stock)
        private
        returns (bool _success)
    {
        if (products[_merchant][_productId].stock > 0) // The product already exists. Update price and increase stock
        {
            products[_merchant][_productId].unitPrice = _unitPrice;
            products[_merchant][_productId].stock += _stock;
        }
        else // The product is new
        {
            products[_merchant][_productId].merchant = msg.sender;
            products[_merchant][_productId].unitPrice = _unitPrice;
            products[_merchant][_productId].stock = _stock;
        }
        return true;
    }

    // PRIVATE
    // To remove a product
    function removeProduct (address _merchant, bytes32 _productId)
        private
        returns (bool _success)
    {
        delete products[_merchant][_productId];
        return true;
    }

    event LogShopPurchaseProduct (address _sender, address _merchant, bytes32 _productId, uint _units, uint256 _unitPrice, uint256 _total);
    // The buyer shall have funded his account BEFORE he can purchase any product
    // The buyer shall have enough balance to purchase the products
    // If he does, then the price will be deducted from his balance
    // A purchase will then be registered with customer's address and product id
    // The product's stock will be updated
    function purchaseProduct (address _merchant, bytes32 _productId, uint _units)
        onlyDepositors
        onlyIfRunning
        public
        returns (bool _success)
    {
        require (_units > 0);
        require (products[_merchant][_productId].stock >= _units); // check stock
        uint256 unitPrice = products[_merchant][_productId].unitPrice;
        uint256 total = unitPrice * _units; // calculate total required balance

        purchases[msg.sender].push(Purchase(_merchant, _productId, _units, unitPrice, total)); //register purchase
        products[_merchant][_productId].stock -= _units; //update stock

        require(spendFunds (total)); //deduct total from buyer
        merchantsSales[_merchant] += total; //account the purchase to the merchant

        LogShopPurchaseProduct (msg.sender, _merchant, _productId, _units, unitPrice, total);
        return true;
    }

    event LogShopMerchantWithdrawFunds (address _sender, uint256 _transferAmount);
    // Merchants withdraw sales funds executing this function
    // The contract will not send funds to any account, instead merchants shall withdraw funds from contract
    function merchantWithdrawFunds ()
        onlyMerchants
        onlyIfRunning
        public
        returns (bool _success)
    {
        require(msg.sender != root); //the root cannot withdraw his own funds
        require(merchantsSales[msg.sender] > 0); //require positive merchant balance | prevents re-entry

        uint256 balance = merchantsSales[msg.sender];
        merchantsSales[msg.sender] = 0; //optimistic accounting

        msg.sender.transfer(balance);

        LogShopMerchantWithdrawFunds (msg.sender, balance);
        return true;
    }
}

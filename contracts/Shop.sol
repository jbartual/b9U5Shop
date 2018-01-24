pragma solidity ^0.4.4;

import "./MyShared/Funded.sol";
import "./OpenZeppelin/SafeMath.sol";

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
    using SafeMath for uint256;

    address private root; //Root administrator
    mapping (address => bool) private administrators;

    mapping (address => bool) private merchants; //key = merchant address
    mapping (address => uint256) private merchantsSales; //account merchant's sales

    struct Product {
        uint256 unitPrice;
        uint stock;
    }
    mapping (address => mapping (bytes32 => Product)) public products; //keys = merchant address, productId

    struct Purchase {
        address[] buyers; //a purchase could be shared by more than one buyer
        address merchant;
        bytes32 productId;
        uint units; //units sold
        uint256 total; //total sale amount
        uint256 paid; //total paid, specially relevant in case of a shared purchase
    }
    mapping (bytes32 => Purchase) public purchases; //key = transaction hash

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
    // To add new merchants
    function addMerchant (address _merchant)
        onlyAdminstrators
        public
        returns (bool _success)
    {
        require(!administrators[_merchant]); // A merchan canot be an administrator

        merchants[_merchant] = true;
        LogShopAddMerchant (msg.sender,  _merchant);
        return true;
    }

        event LogShopRemoveMerchant (address _sender, address _merchant);
    // To remove merchants
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

        event LogShopMerchantWithdrawFunds (address _sender, uint256 _transferAmount);
    // Merchants withdraw sales funds executing this function
    // The contract will not send funds to any account, instead merchants shall withdraw funds from the contract themselves
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

        event LogShopAddProduct (address _sender, bytes32 _productId, uint256 _unitPrice, uint _stock);
    // To add a new product
    function addProduct (bytes32 _productId, uint256 _unitPrice, uint _stock)
        onlyMerchants
        onlyIfRunning
        public
        returns (bool _success)
    {
        products[msg.sender][_productId].unitPrice = _unitPrice;
        products[msg.sender][_productId].stock += _stock;

        LogShopAddProduct (msg.sender, _productId, _unitPrice, _stock);
        return true;
    }

        event LogShopRemoveProduct (address _sender, bytes32 _productId);
    // To remove a product
    function removeProduct (bytes32 _productId)
        onlyMerchants
        onlyIfRunning
        public
        returns (bool _success)
    {
        delete products[msg.sender][_productId];

        LogShopRemoveProduct (msg.sender, _productId);
        return true;
    }

        event LogShopPurchaseProduct (address _sender, address _merchant, bytes32 _productId, uint _units, uint256 _unitPrice, uint256 _total, uint256 _amount, bytes32 _txHash);
    // The buyer shall have funded his account BEFORE he can purchase any product
    // The buyer shall have enough balance to purchase the products
    // If he does, then the total amount will be deducted from his balance
    // A purchase will then be registered with customer's address and product id
    // The product's stock will be updated
    // The sale amount will be credited to the merchant
    function purchaseProduct (address _merchant, bytes32 _productId, uint _units, uint256 _amount)
        onlyDepositors
        onlyIfRunning
        public
        returns (bytes32 _txHash)
    {
        require (_units > 0);
        require (products[_merchant][_productId].stock >= _units); // check stock
        uint256 unitPrice = products[_merchant][_productId].unitPrice;
        uint256 total = unitPrice * _units; // calculate total required balance
        bytes32 txHash;

        if (_amount >= total) //the purchase is not shared
        {
            txHash = registerPurchase (_merchant, _productId, _units, total, total); //register the purchase
            spendFunds (total); //deduct total from buyer
            merchantsSales[_merchant] += total; //account the purchase to the merchant
            //here we could call a delivery function to send the products to the buyer
        }
        else //the purchase is shared
        {
            txHash = registerPurchase (_merchant, _productId, _units, total, _amount); //register the purchase
            spendFunds (_amount); //deduct _amountPaid from buyer
            //do not account the purchase to the merchant as the sale is not fully paid
        }

        require(txHash != 0);

        LogShopPurchaseProduct (msg.sender, _merchant, _productId, _units, unitPrice, total, _amount, txHash);
        return txHash;
    }

        event LogShopUpdatePurchaseSharedProduct (address _sender, bytes32 _txHash, uint256 _share, uint256 _paid, uint256 _remainingTotal);
    // co-purchase by different buyers
    // If the purchase is totally paid off the sale will be credited to the merchant
    function updatePurchaseSharedProduct (bytes32 _txHash, uint256 _amount)
        onlyDepositors
        onlyIfRunning
        public
        returns (uint256 _remainingTotal)
    {
        uint256 total = purchases[_txHash].total;
        uint256 paid = purchases[_txHash].paid;

        require (total > paid); //ensure that there is amount left to be paid

        uint256 remainingTotal;
        uint256 toPay;

        if (_amount > (total - paid)) // sending more funds than remaining total
            toPay = _amount - (total - paid);
        else
            toPay = _amount;

        purchases[_txHash].buyers.push(msg.sender);
        purchases[_txHash].paid += toPay;
        paid += toPay;

        if (paid == total) //if it is completely paid then
        {
            merchantsSales[purchases[_txHash].merchant] += total; //account the purchase to the merchant
            //here we could call a delivery function to send the products to the buyer
            remainingTotal = 0;
        }
        else
        {
            remainingTotal = total - paid;
        }

        spendFunds (toPay); //deduct amount from buyer

        LogShopUpdatePurchaseSharedProduct (msg.sender, _txHash, _amount, toPay, remainingTotal);
        return remainingTotal;
    }

        event LogShopRegisterPurchase (address _sender, address _merchant, bytes32 _productId, uint _units, uint256 _total, uint256 _paid, bytes32 _txHash);
    //Register the purchase in the struct
    function registerPurchase (address _merchant, bytes32 _productId, uint _units, uint256 _total, uint256 _paid)
        onlyDepositors
        onlyIfRunning
        private
        returns (bytes32 _txHash)
    {
        bytes32 txHash;

        txHash = keccak256(_merchant, _productId, _total, msg.data); //create a sales hash
            purchases[txHash].buyers.push(msg.sender); //register purchase
            purchases[txHash].merchant = _merchant;
            purchases[txHash].productId = _productId;
            purchases[txHash].units = _units;
            purchases[txHash].total = _total;
            purchases[txHash].paid += _paid;
        
        if (products[_merchant][_productId].stock == _units)
            delete products[_merchant][_productId];
        else
            products[_merchant][_productId].stock -= _units; //update stock

        LogShopRegisterPurchase (msg.sender, _merchant, _productId, _units, _total, _paid, txHash);
        return txHash;
    }
}

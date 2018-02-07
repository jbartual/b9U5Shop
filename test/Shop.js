var Shop = artifacts.require("./Shop.sol");

contract('Shop', function(accounts) {
  var i; //stores the contract instance

  var a0 = accounts[0];
  var a1 = accounts[1];
  var a2 = accounts[2];
  var a3 = accounts[3];

  beforeEach (function(){
    return Shop.new({from:a0}).then((instance) => {
      i = instance;
    })
  });


  it("By default a0 is administrator and merchant", () => {
    console.log ("it: By default a0 is administrator and merchant");
    return i.isShopOwner.call(a0).then((r) => {
        console.log ("    Is a0 administrator? " + r.toString());
        assert.equal(r.toString(), "true", "    ERROR: By default a0 shall be administrator");
        return i.isMerchant.call(a0);
    }).then((r) => {
        console.log ("    Is a0 merchant? " + r.toString());
        assert.equal(r.toString(), "true", "    ERROR: By default a0 shall be merchant");
    });
  });

  it("a0 adds and removes a1 to administrators and merchants", () => {
    console.log ("it: a0 adds and removes a1 to administrators and merchants");
    console.log ("    a0 adds a1 to shopOwners...");
    return i.addShopOwner(a1, {from:a0}).then(() => {
        return i.isShopOwner(a1);
    }).then((r) => {
        console.log ("    Is a1 administrator? " + r.toString());
        assert.equal(r.toString(), "true", "    ERROR: a1 shall be administrator");
        console.log ("    a0 removes a1 from administrators");
        return i.removeShopOwner(a1,{from:a0});
    }).then (() => {
        return i.isShopOwner(a1);
    }).then((r) => {
        console.log ("    Is a1 administrator? " + r.toString());
        assert.equal(r.toString(), "false", "    ERROR: a1 shall NOT be administrator");
        console.log ("    a0 adds a1 to merchants");
        return i.shopAddMerchant(a1,{from:a0});
    }).then (() => {
        return i.isMerchant(a1);
    }).then((r) => {
        console.log ("    Is a1 merchant? " + r.toString());
        assert.equal(r.toString(), "true", "    ERROR: a1 shall be merchant");
        console.log ("    a0 removes a1 from merchants");
        return i.shopRemoveMerchant(a1);
    }).then(() => {
        return i.isMerchant(a1);
    }).then((r) => {
        console.log ("    Is a1 merchant? " + r.toString());
        assert.equal(r.toString(), "false", "    ERROR: a1 shall NOT be merchant");
    });
  });

  it("a0 adds a product. a0 makes a1 merchant. a1 adds a product. Both remove their products", () => {
    let a0ProductId = "shop01AA";
    let a0UnitPrice = web3.toWei(2,"ether");
    let a0Stock = 5;

    let a1ProductId = "merchant01AA";
    let a1UnitPrice = web3.toWei(2,"ether");
    let a1Stock = 2;

    console.log ("it: a0 adds a product. a0 makes a1 merchant. a1 adds a product. Both remove their products");
    console.log ("    a0 adds 1 product...");
    return i.shopAddProduct (a0ProductId, a0UnitPrice, a0Stock, {from:a0}).then (() => {
        return i.getInfoProduct.call(a0, a0ProductId);
    }).then ((r) => {
        console.log ("      Product Id = " + a0ProductId.toString());
        console.log ("      Unit Price = " + web3.fromWei(r[0],"ether").toString());
        console.log ("      Stock = " + r[1].toString());
        assert.equal(+r[0], +a0UnitPrice, "    ERROR: Unit price shall be " + a0UnitPrice.toString());
        console.log ("    a0 adds a1 as merchant....");
        return i.shopAddMerchant(a1,{from:a0});
    }).then (() => {
        return i.isMerchant.call(a1);
    }).then((r) => {
        console.log ("    Is a1 merchant? " + r.toString());
        assert.equal(r.toString(), "true", "    ERROR: a1 shall be merchant");
        console.log ("    a1 adds 1 merchant product...");
        return i.shopAddProduct(a1ProductId, a1UnitPrice, a1Stock, {from:a1});
    }).then(() => {
        return i.getInfoProduct.call(a1, a1ProductId);
    }).then ((r) => {
        console.log ("      Product Id = " + a1ProductId.toString());
        console.log ("      Unit Price = " + web3.fromWei(r[0],"ether").toString());
        console.log ("      Stock = " + r[1].toString());
        assert.equal(+r[0], +a1UnitPrice, "    ERROR: Unit price shall be " + a1UnitPrice.toString());
        console.log ("    a1 tries to remove a0 product. a1 shall fail.");
        return i.shopRemoveProduct (a0ProductId, {from:a1});
    }).then (() => {
        console.log ("    a0 product shall continue to exists...");
        return i.getInfoProduct.call(a0, a0ProductId);
    }).then ((r) => {
        console.log ("      Unit Price = " + web3.fromWei(r[0],"ether").toString());
        console.log ("      Stock = " + r[1].toString());
        assert.equal(+r[0], +a0UnitPrice, "    ERROR: a0 product shall continue to exists");
        console.log ("    a1 removes his product...");
        return i.shopRemoveProduct (a1ProductId, {from:a1});
    }).then (() => {
        console.log ("    a1 product shall not exist anymore...");
        return i.getInfoProduct.call(a1, a1ProductId);
    }).then ((r) => {
        console.log ("      Unit Price = " + web3.fromWei(r[0],"ether").toString());
        console.log ("      Stock = " + r[1].toString());
        assert.equal(+r[0], 0, "    ERROR: a1 product shall not exist anymore");
        console.log ("    a0 removes his product...");
        return i.shopRemoveProduct(a0ProductId, {from:a0});
    }).then (() => {
        console.log ("    a0 product shall not exists anymore...");
        return i.getInfoProduct.call(a0, a0ProductId);
    }).then ((r) => {
        console.log ("      Unit Price = " + web3.fromWei(r[0],"ether").toString());
        console.log ("      Stock = " + r[1].toString());
        assert.equal(+r[0], 0, "    ERROR: a0 product shall not exist anymore");
    });
  });

  it ("a0 adds a1 as merchant. a1 adds 2 products. a2 buys 1 product. a1 withdraw the funds from the sale.", () => {
    let p1ProductId = "ma101AA";
    let p1UnitPrice = web3.toWei(2,"ether");
    let p1Stock = 5;

    let p2ProductId = "ma102AA";
    let p2UnitPrice = web3.toWei(1,"ether");
    let p2Stock = 2;

    let a2Deposit = parseInt(p2UnitPrice*p2Stock) + parseInt(p2UnitPrice);

    console.log ("it: a0 adds a1 as merchant. a1 adds 2 products. a2 buys 1 product. a1 withdraw the funds from the sale.");
    console.log ("    a0 adds a1 as merchant...");
    return i.shopAddMerchant(a1, {from:a0}).then(() => {
        return i.isMerchant(a1);
    }).then((r) => {
        console.log ("    Is a1 merchant? " + r.toString());
        assert.equal(r.toString(), "true", "    ERROR: a1 shall be merchant");
        console.log ("    a1 adds first product...");
        return i.shopAddProduct(p1ProductId, p1UnitPrice, p1Stock, {from:a1});
    }).then(() => {
        return i.getInfoProduct.call(a1, p1ProductId);
    }).then ((r) => {
        console.log ("      Product Id = " + p1ProductId.toString());
        console.log ("      Unit Price = " + web3.fromWei(r[0],"ether").toString());
        console.log ("      Stock = " + r[1].toString());
        assert.equal(+r[0], +p1UnitPrice, "    ERROR: The product is not well recorded");
        console.log ("    a1 adds second product...");
        return i.shopAddProduct(p2ProductId, p2UnitPrice, p2Stock, {from:a1});
    }).then(() => {
        return i.getInfoProduct.call(a1, p2ProductId);
    }).then ((r) => {
        console.log ("      Product Id = " + p2ProductId.toString());
        console.log ("      Unit Price = " + web3.fromWei(r[0],"ether").toString());
        console.log ("      Stock = " + r[1].toString());
        assert.equal(+r[0], +p2UnitPrice, "    ERROR: The product is not well recorded");
        console.log ("    a2 decides to buy the second product");
        return i.purchaseProduct (a1, p2ProductId, p2Stock, {from:a2, value:p2UnitPrice*p2Stock});
    }).then(() => {
        console.log ("    Product's updated info:")
        return i.getInfoProduct.call(a1, p2ProductId);
    }).then ((r) => {
        console.log ("      Product Id = " + p2ProductId.toString());
        console.log ("      Unit Price = " + web3.fromWei(r[0],"ether").toString());
        console.log ("      Stock = " + r[1].toString());
        assert.equal(+r[1], +0, "    ERROR: The product shall have 0 stock");
        console.log ("    a2 buys tries to buy one more unit of the second product. It shall fail as no stock is left...");
        return i.purchaseProduct (a1, p2ProductId, 1, {from:a2, value:p2UnitPrice});
    }).catch(() => {
        console.log ("    Sale total shall been assigned to a1, the merchant...");
        return web3.eth.getBalance(a1);
    }).then((r) => {
        console.log ("    a1 address balance = " + web3.fromWei(r,"ether").toString());
        return i.getInfoMerchantSales.call(a1);
    }).then((r) => {
        console.log ("    a1 balance in Shop account = " + web3.fromWei(r,"ether").toString());
        assert.equal(+r, +p2UnitPrice*p2Stock, "    ERROR: a1 balance shall be of " + (p2UnitPrice*p2Stock).toString());
        console.log ("    a1 withdraws his funds...");
        return i.shopMerchantWithdrawAllBalance({from:a1});
    }).then(() => {
        return i.getInfoMerchantSales.call(a1);
    }).then((r) => {
        console.log ("    a1 balance in Shop account = " + web3.fromWei(r,"ether").toString());
        assert.equal(+r, 0, "    ERROR: a1 balance shall be 0");
        return web3.eth.getBalance(a1);
    }).then((r) => {
        console.log ("    a1 address balance = " + web3.fromWei(r,"ether").toString());
    });
  });


  it("a1 adds 1 expensive product. a2 and a3 share the purchase of it 80%-20%", () => {
    let a1ProductId = "merchant01AA";
    let a1UnitPrice = web3.toWei(5,"ether");
    let a1Stock = 1;

    let a2Deposit = web3.toWei(4,"ether");
    let a3Deposit = web3.toWei(1,"ether");

    let hashTicket;

    console.log ("it: a1 adds 1 expensive product. a2 and a3 share the purchase of it 80%-20%");
    console.log ("    a0 adds a1 as merchant...");
    return i.shopAddMerchant(a1, {from:a0}).then(() => {
        return i.isMerchant(a1);
    }).then((r) => {
        console.log ("    Is a1 merchant? " + r.toString());
        assert.equal(r.toString(), "true", "    ERROR: a1 shall be merchant");
        console.log ("    a1 adds the expensive product...");
        return i.shopAddProduct(a1ProductId, a1UnitPrice, a1Stock, {from:a1});
    }).then(() => {
        return i.getInfoProduct.call(a1, a1ProductId);
    }).then ((r) => {
        console.log ("      Product Id = " + a1ProductId.toString());
        console.log ("      Unit Price = " + web3.fromWei(r[0],"ether").toString());
        console.log ("      Stock = " + r[1].toString());
        assert.equal(+r[0], +a1UnitPrice, "    ERROR: The product is not well recorded");
        console.log ("    a2 start the shared purchase of a1 product...")        
        return i.purchaseSharedProduct(a1, a1ProductId, 1, {from:a2, value:a2Deposit});
    }).then((r) => {
        hashTicket =  r.logs[3].args._hashTicket;
        console.log ("    Hash Ticket = " + hashTicket);
        console.log ("    Product Info...")
        return i.getInfoProduct.call(a1, a1ProductId);
    }).then ((r) => {
        console.log ("      Product Id = " + a1ProductId.toString());
        console.log ("      Unit Price = " + web3.fromWei(r[0],"ether").toString());
        console.log ("      Stock = " + r[1].toString());
        assert.equal(+r[1], 0, "    ERROR: stock shall be 0");
        return i.getInfoMerchantSales.call(a1);
    }).then((r) => {
        console.log ("    a1 (merchant) balance in the Shop (should be 0) = " + r.toString());
        assert.equal(+r, 0, "    ERROR: a1 balance shall be 0");
        console.log ("    a3 joins the shared purchase of a1 product...")        
        return i.updatePurchaseSharedProduct(hashTicket, {from:a3, value:a3Deposit});
    }).then((r) => {
        console.log ("    Remaining Total = " + r.logs[3].args._remainingTotal);
        return i.getInfoMerchantSales.call(a1);
    }).then((r) => {
        console.log ("    a1 (merchant) balance in the Shop = " + web3.fromWei(r,"ether").toString());
        assert.equal(+r, +a1UnitPrice, "    ERROR: a1 balance shall be " + a1UnitPrice.toString());
        console.log ("    a1 withdraws his funds...");
        return i.shopMerchantWithdrawAllBalance({from:a1});
    }).then(() => {
        return i.getInfoMerchantSales.call(a1);
    }).then((r) => {
        console.log ("    a1 balance in Shop account = " + web3.fromWei(r,"ether").toString());
        assert.equal(+r, 0, "    ERROR: a1 balance shall be 0");
        return web3.eth.getBalance(a1);
    }).then((r) => {
        console.log ("    a1 address balance = " + web3.fromWei(r,"ether").toString());
    });
  });
});
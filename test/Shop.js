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
    return i.isAdministrator.call(a0).then((r) => {
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
    console.log ("    a0 adds a1 to adminsitrators...");
    return i.addAdministrator(a1, {from:a0}).then(() => {
        return i.isAdministrator(a1);
    }).then((r) => {
        console.log ("    Is a1 administrator? " + r.toString());
        assert.equal(r.toString(), "true", "    ERROR: a1 shall be administrator");
        console.log ("    a0 removes a1 from administrators");
        return i.removeAdministrator(a1,{from:a0});
    }).then (() => {
        return i.isAdministrator(a1);
    }).then((r) => {
        console.log ("    Is a1 administrator? " + r.toString());
        assert.equal(r.toString(), "false", "    ERROR: a1 shall NOT be administrator");
        console.log ("    a0 adds a1 to merchants");
        return i.addMerchant(a1,{from:a0});
    }).then (() => {
        return i.isMerchant(a1);
    }).then((r) => {
        console.log ("    Is a1 merchant? " + r.toString());
        assert.equal(r.toString(), "true", "    ERROR: a1 shall be merchant");
        console.log ("    a0 removes a1 from merchants");
        return i.removeMerchant(a1);
    }).then(() => {
        return i.isMerchant(a1);
    }).then((r) => {
        console.log ("    Is a1 merchant? " + r.toString());
        assert.equal(r.toString(), "false", "    ERROR: a1 shall NOT be merchant");
    });
  });

  it("a0 adds a product. a0 makes a1 merchant. a1 adds a product. Both remove their products", () => {
    let shopProductId = "shop01AA";
    let shopUnitPrice = web3.toWei(2,"ether");
    let shopStock = 5;

    let merchantProductId = "merchant01AA";
    let merchantUnitPrice = web3.toWei(2,"ether");
    let merchantStock = 2;

    console.log ("it: a0 adds a product. a0 makes a1 merchant. a1 adds a product. Both remove their products");
    console.log ("    a0 adds 1 product...");
    return i.addShopProduct (shopProductId, shopUnitPrice, shopStock, {from:a0}).then (() => {
        return i.getProductInfo.call(a0, shopProductId);
    }).then ((r) => {
        console.log ("      Product Id = " + shopProductId.toString());
        console.log ("      Unit Price = " + web3.fromWei(r[0],"ether").toString());
        console.log ("      Stock = " + r[1].toString());
        assert.equal(+r[0], +shopUnitPrice, "    ERROR: Unit price shall be " + shopUnitPrice.toString());
        console.log ("    a0 adds a1 as merchant....");
        return i.addMerchant(a1,{from:a0});
    }).then (() => {
        return i.isMerchant.call(a1);
    }).then((r) => {
        console.log ("    Is a1 merchant? " + r.toString());
        assert.equal(r.toString(), "true", "    ERROR: a1 shall be merchant");
        console.log ("    a1 adds 1 merchant product...");
        return i.addMerchantProduct(merchantProductId, merchantUnitPrice, merchantStock, {from:a1});
    }).then(() => {
        return i.getProductInfo.call(a1, merchantProductId);
    }).then ((r) => {
        console.log ("      Product Id = " + merchantProductId.toString());
        console.log ("      Unit Price = " + web3.fromWei(r[0],"ether").toString());
        console.log ("      Stock = " + r[1].toString());
        assert.equal(+r[0], +merchantUnitPrice, "    ERROR: Unit price shall be " + merchantUnitPrice.toString());
        console.log ("    a1 tries to remove a0 product. a1 shall fail.");
        return i.removeShopProduct (shopProductId, {from:a1});
    }).then (() => {
        console.log ("    a0 product shall continue to exists...");
        return i.getProductInfo.call(a0, shopProductId);
    }).then ((r) => {
        console.log ("      Unit Price = " + web3.fromWei(r[0],"ether").toString());
        console.log ("      Stock = " + r[1].toString());
        assert.equal(+r[0], +shopUnitPrice, "    ERROR: a0 product shall continue to exists");
        console.log ("    a1 removes his product...");
        return i.removeMerchantProduct (merchantProductId, {from:a1});
    }).then (() => {
        console.log ("    a1 product shall not exist anymore...");
        return i.getProductInfo.call(a1, merchantProductId);
    }).then ((r) => {
        console.log ("      Unit Price = " + web3.fromWei(r[0],"ether").toString());
        console.log ("      Stock = " + r[1].toString());
        assert.equal(+r[0], 0, "    ERROR: a1 product shall not exist anymore");
        console.log ("    a0 removes his product...");
        return i.removeShopProduct(shopProductId, {from:a0});
    }).then (() => {
        console.log ("    a0 product shall not exists anymore...");
        return i.getProductInfo.call(a0, shopProductId);
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
    return i.addMerchant(a1, {from:a0}).then(() => {
        return i.isMerchant(a1);
    }).then((r) => {
        console.log ("    Is a1 merchant? " + r.toString());
        assert.equal(r.toString(), "true", "    ERROR: a1 shall be merchant");
        console.log ("    a1 adds first product...");
        return i.addMerchantProduct(p1ProductId, p1UnitPrice, p1Stock, {from:a1});
    }).then(() => {
        return i.getProductInfo.call(a1, p1ProductId);
    }).then ((r) => {
        console.log ("      Product Id = " + p1ProductId.toString());
        console.log ("      Unit Price = " + web3.fromWei(r[0],"ether").toString());
        console.log ("      Stock = " + r[1].toString());
        assert.equal(+r[0], +p1UnitPrice, "    ERROR: The product is not well recorded");
        console.log ("    a1 adds second product...");
        return i.addMerchantProduct(p2ProductId, p2UnitPrice, p2Stock, {from:a1});
    }).then(() => {
        return i.getProductInfo.call(a1, p2ProductId);
    }).then ((r) => {
        console.log ("      Product Id = " + p2ProductId.toString());
        console.log ("      Unit Price = " + web3.fromWei(r[0],"ether").toString());
        console.log ("      Stock = " + r[1].toString());
        assert.equal(+r[0], +p2UnitPrice, "    ERROR: The product is not well recorded");
        console.log ("    a2 decides to buy the second product");
        console.log ("    a2 needs first to fund his account with enough balance...");
        return web3.eth.getBalance(a2);
    }).then((r) => {
        console.log ("    a2 address balance = " + web3.fromWei(r,"ether").toString());
        console.log ("    a2 funds to deposit = " + web3.fromWei(a2Deposit,"ether").toString());
        return i.depositFunds({from:a2, value:+a2Deposit});
    }).then(() => {
        return i.getDepositorBalance.call(a2);
    }).then((r) => {
        console.log ("    a2 balance in Shop account = " + web3.fromWei(r,"ether").toString());
        assert.equal(+r, +a2Deposit, "    ERROR: a2 deposit wasn't successful");
        console.log ("    a2 buys all units of the second product...");
        return i.purchaseProduct (a1, p2ProductId, p2Stock, {from:a2});
    }).then(() => {
        return i.getDepositorBalance.call(a2);
    }).then((r) => {
        console.log ("    a2 balance in Shop account = " + web3.fromWei(r,"ether").toString());
        assert.equal(+r, +p2UnitPrice, "    ERROR: a2 balance shall be " + p2UnitPrice.toString());
        console.log ("    Product's updated info:")
        return i.getProductInfo.call(a1, p2ProductId);
    }).then ((r) => {
        console.log ("      Product Id = " + p2ProductId.toString());
        console.log ("      Unit Price = " + web3.fromWei(r[0],"ether").toString());
        console.log ("      Stock = " + r[1].toString());
        assert.equal(+r[1], +0, "    ERROR: The product shall have 0 stock");
        console.log ("    a2 buys tries to buy one more unit of the second product. It shall fail as no stock is left...");
        return i.purchaseProduct (a1, p2ProductId, 1);
    }).then(() => {
        return i.getDepositorBalance.call(a2);
    }).then((r) => {
        console.log ("    a2 balance in Shop account = " + web3.fromWei(r,"ether").toString());
        assert.equal(+r, +p2UnitPrice, "    ERROR: a2 balance shall be of " + p2UnitPrice.toString());
        console.log ("    Sale total shall been assigned to a1, the merchant...");
        return web3.eth.getBalance(a1);
    }).then((r) => {
        console.log ("    a1 address balance = " + web3.fromWei(r,"ether").toString());
        return i.getMerchantInfo.call(a1);
    }).then((r) => {
        console.log ("    a1 balance in Shop account = " + web3.fromWei(r,"ether").toString());
        assert.equal(+r, +p2UnitPrice*p2Stock, "    ERROR: a1 balance shall be of " + (p2UnitPrice*p2Stock).toString());
        console.log ("    a1 withdraws his funds...");
        return i.merchantWithdrawFunds({from:a1});
    }).then(() => {
        return i.getMerchantInfo.call(a1);
    }).then((r) => {
        console.log ("    a1 balance in Shop account = " + web3.fromWei(r,"ether").toString());
        assert.equal(+r, 0, "    ERROR: a1 balance shall be 0");
        return web3.eth.getBalance(a1);
    }).then((r) => {
        console.log ("    a1 address balance = " + web3.fromWei(r,"ether").toString());
    });
  });
});
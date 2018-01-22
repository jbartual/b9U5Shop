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

  it("a0 adds a product. a0 makes a1 merchant. a1 adds a product. both removes their products", () => {
    let shopProductId = "shop01AA";
    let shopUnitPrice = 100;
    let shopStock = 5;

    let merchantProductId = "merchant01AA";
    let merchantUnitPrice = 80;
    let merchantStock = 2;

    console.log ("it: a0 adds a product. a0 makes a1 merchant. a1 adds a product. both removes their products");
    console.log ("    a0 adds 1 product...");
    return i.addShopProduct (shopProductId, shopUnitPrice, shopStock, {from:a0}).then (() => {
        return i.getProductInfo.call(a0, shopProductId);
    }).then ((r) => {
        console.log ("      Unit Price = " + r[0].toString());
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
        console.log ("      Unit Price = " + r[0].toString());
        console.log ("      Stock = " + r[1].toString());
        assert.equal(+r[0], +merchantUnitPrice, "    ERROR: Unit price shall be " + merchantUnitPrice.toString());
        console.log ("    a1 tries to remove a0 product. a1 shall fail.");
        return i.removeShopProduct (shopProductId, {from:a1});
    }).then (() => {
        console.log ("    a0 product shall continue to exists...");
        return i.getProductInfo.call(a0, shopProductId);
    }).then ((r) => {
        console.log ("      Unit Price = " + r[0].toString());
        console.log ("      Stock = " + r[1].toString());
        assert.equal(+r[0], +shopUnitPrice, "    ERROR: a0 product shall continue to exists");
        console.log ("    a1 removes his product...");
        return i.removeMerchantProduct (merchantProductId, {from:a1});
    }).then (() => {
        console.log ("    a1 product shall not exist anymore...");
        return i.getProductInfo.call(a1, merchantProductId);
    }).then ((r) => {
        console.log ("      Unit Price = " + r[0].toString());
        console.log ("      Stock = " + r[1].toString());
        assert.equal(+r[0], 0, "    ERROR: a1 product shall not exist anymore");
        console.log ("    a0 removes his product...");
        return i.removeShopProduct(shopProductId, {from:a0});
    }).then (() => {
        console.log ("    a0 product shall not exists anymore...");
        return i.getProductInfo.call(a0, shopProductId);
    }).then ((r) => {
        console.log ("      Unit Price = " + r[0].toString());
        console.log ("      Stock = " + r[1].toString());
        assert.equal(+r[0], 0, "    ERROR: a0 product shall not exist anymore");
    });
  });
});
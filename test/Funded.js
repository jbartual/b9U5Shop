var Funded = artifacts.require("./Funded.sol");

contract('Funded', function(accounts) {
  var i; //stores the contract instance

  var a0 = accounts[0];
  var a1 = accounts[1];
  var a2 = accounts[2];
  var a3 = accounts[3];

  beforeEach (function(){
    return Funded.new(a0, {from:a0}).then((instance) => {
      i = instance;
    })
  });

  it("By default a0 shall be cashier", () => {
    console.log ("it: By default a0 shall be cashier");
    return i.isCashier.call(a0).then((r) => {
        console.log ("    Is a0 cashier? " + r.toString());
        assert.equal(r.toString(), "true", "    ERROR: By default a0 shall be cashier");
    });
  });

  it("a1 deposit funds and withdraws half" , () => {
    let deposit = 2;
    console.log ("it: a1 deposit funds and withdraws half");
    console.log ("    a1 deposits funds. Amount = " + deposit.toString());
    return i.depositFunds({from:a1, value:deposit}).then(() => {
        return i.getContractBalance.call();
    }).then((r) => {
        console.log ("    Contract balance = " + r.toString());
        assert.equal (+r, +deposit, "    ERROR: Contract balance shall be " + deposit.toString());
        console.log ("    a1 withdraws half of the amount (" + (deposit/2).toString() +")");
        return i.withdrawFunds(deposit/2, {from:a1});
    }).then(() => {
        return i.getContractBalance.call();
    }).then ((r) => {
        console.log ("    Contract balance = " + r.toString());
        assert.equal (+r, +deposit/2, "    ERROR: Contract balance shall be " + (deposit/2).toString());
    })
  });

  it("a1 deposit funds a2 tries to withdraw the funds. a2 fails" , () => {
    let deposit = 2;
    console.log ("it: a1 deposit funds a2 tries to withdraw the funds. a2 fails");
    console.log ("    a1 deposits funds. Amount = " + deposit.toString());
    return i.depositFunds({from:a1, value:deposit}).then(() => {
        return i.getContractBalance.call();
    }).then((r) => {
        console.log ("    Contract balance = " + r.toString());
        assert.equal (+r, +deposit, "    ERROR: Contract balance shall be " + deposit.toString());
        console.log ("    a2 tries to withdraw funds. a2 fails");
        return i.withdrawFunds(deposit, {from:a2});
    }).catch(() => {
        return i.getContractBalance.call();
    }).then ((r) => {
        console.log ("    Contract balance = " + r.toString());
        assert.equal (+r, +deposit, "    ERROR: Contract balance shall be " + deposit.toString());
    })
  });

  it("a1 deposits funds. a2 deposits funds too. a2 tries to withdraw a1 funds. a2 fails" , () => {
    let deposit = 2;
    console.log ("it: a1 deposits funds. a2 deposits funds too. a2 tries to withdraw a1 funds. a2 fails");
    console.log ("    a1 deposits funds. Amount = " + deposit.toString());
    return i.depositFunds({from:a1, value:deposit}).then(() => {
        return i.getContractBalance.call();
    }).then((r) => {
        console.log ("    Contract balance = " + r.toString());
        console.log ("    a2 deposits funds. Amount = " + (deposit/2).toString());
        return i.depositFunds({from:a2, value:(deposit/2)});
    }).then(() => {
        return i.getContractBalance.call();
    }).then ((r) => {
        console.log ("    Contract balance = " + r.toString());
        console.log ("    Check a1 depositor balance...");
        return i.getDepositorBalance.call(a1);
    }).then ((r) => {
        console.log ("    a1 depositor balance = " + r.toString());
        console.log ("    Check a2 depositor balance...");
        return i.getDepositorBalance.call(a2);
    }).then ((r) => {
        console.log ("    a2 depositor balance = " + r.toString());
        console.log ("    a2 tries to withdraw a1's balance...")
        return i.withdrawFunds(deposit, {from:a2});
    }).catch(() => {
        console.log ("    Check a1 depositor balance...");
        return i.getDepositorBalance.call(a1);
    }).then ((r) => {
        console.log ("    a1 depositor balance = " + r.toString());
        console.log ("    Check a2 depositor balance...");
        return i.getDepositorBalance.call(a2);
    }).then ((r) => {
        console.log ("    a2 depositor balance = " + r.toString());
        return i.getContractBalance.call();
    }).then ((r) => {
        console.log ("    Contract balance = " + r.toString());
        assert.equal (+r, +deposit + +(deposit/2), "    ERROR: Contract balance shall be " + (deposit + (deposit/2)).toString());
    })
  });

});
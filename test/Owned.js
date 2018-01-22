var Owned = artifacts.require("./Owned.sol");

contract('Owned', function(accounts) {
  var i; //stores the contract instance

  var a0 = accounts[0];
  var a1 = accounts[1];
  var a2 = accounts[2];
  var a3 = accounts[3];

  beforeEach (function(){
    return Owned.new({from:a0}).then((instance) => {
      i = instance;
    })
  });

  it("Owner shall be accounts[0]", () => {
    console.log ("it: Owner shall be accounts[0] = " + a0.toString());
    return i.getOwner.call().then((r) => {
        console.log ("    Owner is " + r.toString());
        assert.equal(r.toString(), a0.toString(), "    ERROR: owner (" + r.toString() +") shall be equal to " + a0.toString());
    });
  });

  it("Change ownership from accounts[0] to accounts[1]", () => {
    console.log ("it: Change ownership from accounts[0] to accounts[1]");
    return i.getOwner.call().then((r) => {
        console.log ("   Current owner is " + r.toString());
        return i.changeOwner(a1, {from:a0});
    }).then(() => {
        return i.confirmChangeOwner({from:a1});
    }).then(() => {
        return i.getOwner.call();
    }).then ((r) => {
        console.log ("    New owner is "  + r.toString());
        assert.equal(r.toString(), a1.toString(), "    ERROR: new owner " + r.toString() +" shall be equal to " + a1.toString());
    })
  });
});

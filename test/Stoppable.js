var Stoppable = artifacts.require("./Stoppable.sol");

contract('Stoppable', function(accounts) {
  var i; //stores the contract instance

  var a0 = accounts[0];
  var a1 = accounts[1];
  var a2 = accounts[2];
  var a3 = accounts[3];

  beforeEach (function(){
    return Stoppable.new({from:a0}).then((instance) => {
      i = instance;
    })
  });

  it("By default contract shall not be stopped", () => {
    console.log ("it: By default contract shall not be stopped");
    return i.isStopped.call().then((r) => {
        console.log ("    Is Contract stopped? " + r.toString());
        assert.equal(r.toString(), "false", "    ERROR: Contract shall not be stopped");
    });
  });

  it("Stop and resume contract", () => {
    console.log ("it: Stop and resume contract");

    return i.isStopped.call().then((r) => {
        console.log ("    Is Contract stopped? " + r.toString());
        console.log ("    Stopping contract...");
        return i.stopContract({from:a0});
    }).then(() => {
        return i.isStopped.call();
    }).then((r) => {
        console.log ("    Is Contract stopped? " + r.toString());
        console.log ("    Resume contract...");
        return i.resumeContract({from:a0})
    }).then(() => {
        return i.isStopped.call();
    }).then((r) => {
        console.log ("    Is Contract stopped? " + r.toString());
        assert.equal(r.toString(), "false", "    ERROR: Contract shall not be stopped");
    })
  });

  it("Try to Stop contract from no Owner account", () => {
    console.log ("it: Try to Stop contract from no Owner account");

    return i.isStopped.call().then((r) => {
        console.log ("    Is Contract stopped? " + r.toString());
        console.log ("    Stopping contract from accounts[1]...");
        return i.stopContract({from:a1});
    }).catch(() => {
        return i.isStopped.call();
    }).then((r) => {
        console.log ("    Is Contract stopped? " + r.toString());
        assert.equal(r.toString(), "false", "    ERROR: Contract shall not be stopped");
    })
  });

  it("Try to Resume a stopped contract from no Owner account", () => {
    console.log ("it: Try to Stop contract from no Owner account");

    return i.isStopped.call().then((r) => {
        console.log ("    Is Contract stopped? " + r.toString());
        console.log ("    Stopping contract from accounts[0]...");
        return i.stopContract({from:a0});
    }).then(() => {
        return i.isStopped.call();
    }).then((r) => {
        console.log ("    Is Contract stopped? " + r.toString());
        console.log ("    Resume contract from accounts[1]...");
        return i.resumeContract({from:a1})
    }).catch(() => {
        return i.isStopped.call();
    }).then((r) => {
        console.log ("    Is Contract stopped? " + r.toString());
        assert.equal(r.toString(), "true", "    ERROR: Contract shall be stopped");
    })
  });

});

var O  = artifacts.require("./Owned.sol");
var S  = artifacts.require("./Stoppable.sol");
var F  = artifacts.require("./FundsManager.sol");
var PM = artifacts.require("./ProductManager.sol");
var MM = artifacts.require("./MerchantManager.sol");

var Shop = artifacts.require("./Shop.sol");

module.exports = function(deployer) {
  deployer.deploy(O);
  deployer.deploy(S);
  deployer.deploy(F);
  deployer.deploy(PM);
  deployer.deploy(MM);

  deployer.deploy(Shop);
};

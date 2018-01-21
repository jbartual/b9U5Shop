var Owned = artifacts.require("./Owned.sol");
var Stoppable = artifacts.require("./Stoppable.sol");
var Funded = artifacts.require("./Funded.sol");
var Shop = artifacts.require("./Shop.sol");

module.exports = function(deployer) {
  deployer.deploy(Owned);
  deployer.deploy(Stoppable);
  deployer.deploy(Funded);
  deployer.deploy(Shop);

};

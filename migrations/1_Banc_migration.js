const Banc = artifacts.require("Banc");

module.exports = function (deployer) {
  deployer.deploy(Banc);
};

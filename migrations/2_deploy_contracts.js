// 27 000 000
// 15% = 4 050 000
// 15 * 6 = 90%
// 4 050 000 * 6 = 24300000
// 10% = 2 700 000

// var CryptoHuntGameIco = artifacts.require('CryptoHuntGameIco');
// module.exports = function(deployer) {
//   deployer.deploy(CryptoHuntGameIco);
// }

var TokenTimedChestMulti = artifacts.require("TokenTimedChestMulti");
module.exports = function(deployer) {
  deployer.deploy(TokenTimedChestMulti);
};

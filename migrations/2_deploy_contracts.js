// 27 000 000
// 15% = 4 050 000
// 15 * 6 = 90%
// 4 050 000 * 6 = 24300000
// 10% = 2 700 000

var CryptoHuntIco = artifacts.require('CryptoHuntIco');
module.exports = function(deployer) {
  deployer.deploy(CryptoHuntIco, 1123200, 86400, "0xA0e0D886043eC37481c9A934feE0EdCd34eee91C", "0xb5F42D711844997443fc72767ee55f43f95CD9Cc");
}
//
// var TestContract = artifacts.require('TestContract');
// module.exports = function(deployer) {
//   deployer.deploy(TestContract);
// }
// var TokenTimedChestMulti = artifacts.require("TokenTimedChestMulti");
// module.exports = function(deployer) {
//   deployer.deploy(TokenTimedChestMulti);
// };

// var CryptoHuntToken = artifacts.require('CryptoHuntToken');
// module.exports = function(deployer) {
//   deployer.deploy(CryptoHuntToken);
// }

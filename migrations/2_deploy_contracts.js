var TimedChest = artifacts.require("TimedChest");

module.exports = function(deployer) {

  //const releaseDelays = [31536000, 31536000, 31536000, 31536000, 31536000, 31536000, 31536000];
  const releaseDelays = [300, 300, 300, 300, 300, 300, 300];
  const amounts = [4050000000000000000, 4050000000000000000, 4050000000000000000, 4050000000000000000, 4050000000000000000, 4050000000000000000, 2700000000000000000];
  const withdrawer = '0x1dF184eA46b58719A7213f4c8a03870A309BcD64';
  const token = '0x840172F8ab2E370c9f28214C752E69aDAc476d3d'

  deployer.deploy(TimedChest, releaseDelays, amounts, withdrawer, token);
};

// 27 000 000
// 15% = 4 050 000
// 15 * 6 = 90%
// 4 050 000 * 6 = 24300000
// 10% = 2 700 000
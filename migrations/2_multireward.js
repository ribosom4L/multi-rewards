const MultiRewards = artifacts.require("MultiRewards");
const { deployProxy } = require('@openzeppelin/truffle-upgrades')

module.exports = async function (deployer, network, accounts) {
  const stakingToken = accounts[0]
  await deployProxy(MultiRewards, [accounts[0], accounts[1]], { deployer })
};

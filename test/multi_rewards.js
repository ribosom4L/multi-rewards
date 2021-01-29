const MultiRewards = artifacts.require("MultiRewards");
const Test1 = artifacts.require("Test1");
const Test2 = artifacts.require("Test2");
const StakingToken = artifacts.require("StakingToken");
const {expectRevert, expectEvent} = require("@openzeppelin/test-helpers");
const BN = require('bn.js')

contract("Multi Rewards", function (accounts) {
  let contract, test1, test2, stakingToken, acc1staked, acc2staked, acc3staked, totalSupply, test1reward, test2reward
  const owner = accounts[0]

  before(async () => {

    test1 = await Test1.new({from: owner})
    test2 = await Test2.new({from: owner})
    stakingToken = await StakingToken.new({from: owner})

    contract = await MultiRewards.new(owner, stakingToken.address)
  })

  it("Should correctly add reward tokens", async () => {
    await contract.addReward(test1.address, owner, 100000, {from: owner})
    const reward1 = await contract.rewardData(test1.address)
    expect(reward1.rewardsDistributor).to.equal(owner)

    await contract.addReward(test2.address, owner, 100000, {from: owner})
    const reward2 = await contract.rewardData(test2.address)
    expect(reward2.rewardsDistributor).to.equal(owner)
  })

  it("user should be able to stake", async () => {
    // transfer staking token to account 1
    acc1staked = new BN(toWei(5000))
    await stakingToken.transfer(accounts[1], acc1staked, {from: owner})
    await stakingToken.approve(contract.address, acc1staked, {from: accounts[1]})
    expectEvent(await contract.stake(acc1staked, {from: accounts[1]}), "Staked")

    acc2staked = new BN(toWei(10000))
    await stakingToken.transfer(accounts[2], acc2staked, {from: owner})
    await stakingToken.approve(contract.address, acc2staked, {from: accounts[2]})
    expectEvent(await contract.stake(acc2staked, {from: accounts[2]}), "Staked")

    acc3staked = new BN(toWei(1000))
    await stakingToken.transfer(accounts[3], acc3staked, {from: owner})
    await stakingToken.approve(contract.address, acc3staked, {from: accounts[3]})
    expectEvent(await contract.stake(acc3staked, {from: accounts[3]}), "Staked")

    totalSupply = acc1staked.add(acc2staked).add(acc3staked)
  });

  it("reward calculations should be correct after notify", async () => {
    test1reward = new BN(toWei(100000))
    test2reward = new BN(toWei(40000))
    await test1.approve(contract.address, test1reward)
    await test2.approve(contract.address, test2reward)
    expectEvent(await contract.notifyRewardAmount(test1.address, test1reward), "RewardAdded")
    expectEvent(await contract.notifyRewardAmount(test2.address, test2reward), "RewardAdded")

    await advanceTimeAndBlock(1000000)

    const earned1test1 = await contract.earned(accounts[1], test1.address)
    const earned1test2 = await contract.earned(accounts[1], test2.address)

    const earned2test1 = await contract.earned(accounts[2], test1.address)
    const earned2test2 = await contract.earned(accounts[2], test2.address)

    const earned3test1 = await contract.earned(accounts[3], test1.address)
    const earned3test2 = await contract.earned(accounts[3], test2.address)

    expect(Number(earned1test1)).to.equal(Number(acc1staked.mul(test1reward).div(totalSupply)))
    expect(Number(earned1test2)).to.equal(Number(acc1staked.mul(test2reward).div(totalSupply)))

    expect(Number(earned2test1)).to.equal(Number(acc2staked.mul(test1reward).div(totalSupply)))
    expect(Number(earned2test2)).to.equal(Number(acc2staked.mul(test2reward).div(totalSupply)))

    expect(Number(earned3test1)).to.equal(Number(acc3staked.mul(test1reward).div(totalSupply)))
    expect(Number(earned3test2)).to.equal(Number(acc3staked.mul(test2reward).div(totalSupply)))

  })

  it("should get correct reward amounts", async () => {
    const reward1 = await contract.getReward({ from: accounts[1] })
    const reward2 = await contract.getReward({ from: accounts[2] })
    const reward3 = await contract.getReward({ from: accounts[3] })

    expectEvent(reward1, "RewardPaid")
    expectEvent(reward2, "RewardPaid")
    expectEvent(reward3, "RewardPaid")

    const earned1test1 = await contract.earned(accounts[1], test1.address)
    const earned1test2 = await contract.earned(accounts[1], test2.address)

    const earned2test1 = await contract.earned(accounts[2], test1.address)
    const earned2test2 = await contract.earned(accounts[2], test2.address)

    const earned3test1 = await contract.earned(accounts[3], test1.address)
    const earned3test2 = await contract.earned(accounts[3], test2.address)

    expect(Number(earned1test1)).to.equal(0)
    expect(Number(earned1test2)).to.equal(0)

    expect(Number(earned2test1)).to.equal(0)
    expect(Number(earned2test2)).to.equal(0)

    expect(Number(earned3test1)).to.equal(0)
    expect(Number(earned3test2)).to.equal(0)
  });

  it("should exit with correct amounts", async () => {
    // add reward first
    test1reward = new BN(toWei(100000))
    test2reward = new BN(toWei(40000))
    await test1.approve(contract.address, test1reward)
    await test2.approve(contract.address, test2reward)
    expectEvent(await contract.notifyRewardAmount(test1.address, test1reward), "RewardAdded")
    expectEvent(await contract.notifyRewardAmount(test2.address, test2reward), "RewardAdded")

    await advanceTimeAndBlock(1000000)

    const earned1test1 = await contract.earned(accounts[1], test1.address)
    const earned1test2 = await contract.earned(accounts[1], test2.address)

    const earned2test1 = await contract.earned(accounts[2], test1.address)
    const earned2test2 = await contract.earned(accounts[2], test2.address)

    const earned3test1 = await contract.earned(accounts[3], test1.address)
    const earned3test2 = await contract.earned(accounts[3], test2.address)

    expect(Number(earned1test1)).to.equal(Number(acc1staked.mul(test1reward).div(totalSupply)))
    expect(Number(earned1test2)).to.equal(Number(acc1staked.mul(test2reward).div(totalSupply)))

    expect(Number(earned2test1)).to.equal(Number(acc2staked.mul(test1reward).div(totalSupply)))
    expect(Number(earned2test2)).to.equal(Number(acc2staked.mul(test2reward).div(totalSupply)))

    expect(Number(earned3test1)).to.equal(Number(acc3staked.mul(test1reward).div(totalSupply)))
    expect(Number(earned3test2)).to.equal(Number(acc3staked.mul(test2reward).div(totalSupply)))

    const exit1 = await contract.exit({ from: accounts[1] })
    const exit2 = await contract.exit({ from: accounts[2] })
    const exit3 = await contract.exit({ from: accounts[3] })

    expect(Number(await stakingToken.balanceOf(accounts[1])), Number(acc1staked))
    expect(Number(await stakingToken.balanceOf(accounts[2])), Number(acc2staked))
    expect(Number(await stakingToken.balanceOf(accounts[3])), Number(acc3staked))

    expect(Number(await contract.balanceOf(accounts[1])), 0)
    expect(Number(await contract.balanceOf(accounts[2])), 0)
    expect(Number(await contract.balanceOf(accounts[3])), 0)
  });

  function secs(sc) {
    return (new Date().getTime() / 1000 + sc * 1000).toFixed(0);
  }

  function advanceTime(time) {
    return new Promise((resolve, reject) => {
      web3.currentProvider.send({
        jsonrpc: "2.0",
        method: "evm_increaseTime",
        params: [time],
        id: new Date().getTime()
      }, (err, result) => {
        if (err) {
          return reject(err);
        }
        return resolve(result);
      });
    });
  }

  const advanceBlock = () => {
    return new Promise((resolve, reject) => {
      web3.currentProvider.send({
        jsonrpc: "2.0",
        method: "evm_mine",
        id: new Date().getTime()
      }, (err, result) => {
        if (err) {
          return reject(err);
        }
        const newBlockHash = web3.eth.getBlock("latest").hash;

        return resolve(newBlockHash);
      });
    });
  };

  const advanceTimeAndBlock = async (time) => {
    await advanceTime(time);
    await advanceBlock();
    return Promise.resolve(web3.eth.getBlock("latest"));
  };

  const toWei = (num) => {
    return web3.utils.toWei(num.toString())
  }

});

const _LightClient = artifacts.require("LightClient.sol");
const _Prover = artifacts.require("Prover.sol");
const _Counter = artifacts.require("Counter.sol");
const _CounterTest = artifacts.require("CounterTest.sol");

module.exports = async function(deployer, network, accounts) {
    await deployer.deploy(_Counter);

    const block = await web3.eth.getBlock(0);
    await deployer.deploy(_LightClient, 6, block);

    let client = await _LightClient.deployed();
    await deployer.deploy(_Prover, client.address);

    let prover = await _Prover.deployed();
    await deployer.deploy(_CounterTest, prover.address);
};

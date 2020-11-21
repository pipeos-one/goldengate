const _LightClient = artifacts.require("LightClient.sol");
const _Prover = artifacts.require("Prover.sol");
const _Counter = artifacts.require("Counter.sol");

module.exports = async function(deployer, network, accounts) {
    await deployer.deploy(_Counter);
    const block = await web3.eth.getBlock(0);
    await deployer.deploy(_LightClient, block.hash, 0);

    let client = await _LightClient.deployed();
    await deployer.deploy(_Prover, client.address);
};

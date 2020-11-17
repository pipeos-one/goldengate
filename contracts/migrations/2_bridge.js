const EthereumClient = artifacts.require("EthereumClient");
const Prover = artifacts.require("Prover");

module.exports = function(deployer) {
    web3.eth.getBlock(0).then(block0 => {
        deployer.deploy(EthereumClient, block0.hash);
    });
    deployer.deploy(Prover);
};


const EthereumClient = artifacts.require('LightClient.sol');
const Prover = artifacts.require('Prover.sol');
const Counter = artifacts.require('Counter.sol');
const Web3 = require('web3');
const { GetProof } = require('eth-proof');
const {
    getReceiptProof,
    getAccountProof,
    getTransactionProof,
} = require('../utils');

const getProof = new GetProof("https://ropsten.infura.io/v3/18559f1ef1204f62b3cd0aec5ae1ab82");

contract('EthereumClient', async accounts => {
    let prover, client, counter;

    it('deploy', async () => {
        client = await EthereumClient.deployed();
        prover = await Prover.deployed();
        counter = await Counter.deployed();
    });

    it('verify Counter two chains', async () => {
        let receipt;
        const chainA = "http://127.0.0.1:8645"
        const chainB = "http://192.168.1.127:8545";
        const _getProof = new GetProof(chainA);
        const address = accounts[1];
        const web3A = new Web3(chainA);
        const web3B = new Web3(chainB);

        const account = web3A.eth.accounts.create();

        const privateKey = "45122bfb302c5e4bb63cf49a46863413557da04b1b5c4a9bdcf36dc728065fa5";
        const acc = web3A.eth.accounts.privateKeyToAccount(privateKey);
        web3A.eth.accounts.wallet.add(acc);
        web3B.eth.accounts.wallet.add(acc);

        const amount = '0.1';
        await web3A.eth.sendTransaction({from: accounts[1], to: account.address, value: web3A.utils.toWei(amount, "ether"), gas: 50000, price: 1});
        console.log('---Sent money on A');
        await web3B.eth.sendTransaction({from: accounts[1], to: account.address, value: web3B.utils.toWei(amount, "ether"), gas: 50000, price: 1});
        console.log('---Sent money on B');


        // Set new address as default
        console.log('---account', account);
        web3A.eth.accounts.wallet.add(account);
        web3A.eth.defaultAccount = account.address;
        console.log('---Added account on A', await web3A.eth.getAccounts());


        web3B.eth.accounts.wallet.add(account);
        web3B.eth.defaultAccount = account.address;
        console.log('---Added account on B', await web3B.eth.getAccounts());

        console.log('nonce A', await web3A.eth.getTransactionCount(account.address));
        console.log('nonce B', await web3B.eth.getTransactionCount(account.address));


        // Deploy Counter on chain A
        const _counterA = new web3A.eth.Contract(counter.constructor._json.abi);
        const counterA = await _counterA.deploy({data: counter.constructor._json.bytecode, arguments: []}).send({
            from: account.address,
            gas: 6000000,
            gasPrice: 1,
        });

        console.log('---Deployed counterA', counterA.options.address);
        console.log('nonce A', await web3A.eth.getTransactionCount(account.address));
        console.log('nonce B', await web3B.eth.getTransactionCount(account.address));


        // Deploy Counter on chain B
        const _counterB = new web3B.eth.Contract(counter.constructor._json.abi);
        const counterB = await _counterB.deploy({data: counter.constructor._json.bytecode, arguments: []}).send({
            from: account.address,
            gas: 6000000,
            gasPrice: 1,
        });

        console.log('---Deployed counterB', counterB.options.address);
        console.log('nonce A', await web3A.eth.getTransactionCount(account.address));
        console.log('nonce B', await web3B.eth.getTransactionCount(account.address));

        assert.equal(counterA.options.address, counterB.options.address, "Counter addresses not equal");

        // Deploy LightClient on chain B
        const _client = new web3B.eth.Contract(client.constructor._json.abi);
        const block = await web3.eth.getBlock('latest');
        const clientB = await _client.deploy({data: client.constructor._json.bytecode, arguments: [block.hash, 0]}).send({
            from: accounts[1],
            gas: 6000000,
            gasPrice: 1,
        });


        console.log('---Deployed clientB', clientB.options.address);

        // Deploy Prover on chain B
        const _proverB = new web3B.eth.Contract(prover.constructor._json.abi);
        const proverB = await _proverB.deploy({data: prover.constructor._json.bytecode, arguments: [clientB.options.address]}).send({
            from: accounts[1],
            gas: 6000000,
            gasPrice: 1,
        });


        console.log('---Deployed proverB', proverB.options.address);

        await testBridge({web3A, web3B, counterA, counterB, prover, proverB, client, clientB, accounts, _getProof, address, increment: 3});

        await testBridge({web3A, web3B, counterA, counterB, prover, proverB, client, clientB, accounts, _getProof, address, increment: 6});

    });
});


async function testBridge({web3A, web3B, counterA, counterB, prover, proverB, client, clientB, accounts, _getProof, address, increment}) {
    let countA = parseInt(await counterA.methods.count().call());
    let countB = parseInt(await counterB.methods.count().call());

    console.log('----counters', countA, countB);


    // Send transaction on Chain A
    receipt = await counterA.methods.incrementCounter(increment).send({from: accounts[1], gas: 200000, gasPrice: 1});
    countA += increment;
    assert.equal(countA, parseInt(await counterA.methods.count().call()));
    console.log('---countA', countA);

    // console.log('----receipt', receipt);

    const header = await web3A.eth.getBlock(receipt.blockNumber);
    const accountProof = await getAccountProof(web3A, _getProof, prover, address, receipt.blockHash);
    const txProof = await getTransactionProof(_getProof, prover, receipt.transactionHash);
    const receiptProof = await getReceiptProof(_getProof, prover, receipt.transactionHash);
    console.log('----proofs gathered');

    // Forward transaction on Chain B
    await clientB.methods._addBlock(header.number, header.hash).send({
        from: accounts[1],
        gas: 6000000,
        gasPrice: 1,
    });

    console.log('----block added');

    console.log('---countB', await counterB.methods.count().call());

    receipt = await proverB.methods.forwardAndVerify(header, accountProof, txProof, receiptProof, address).send({
        from: accounts[1],
        gas: 6000000,
        gasPrice: 1,
    });

    console.log('----forwardAndVerify done', receipt);

    countB += increment;
    console.log('---countB should', countB)
    console.log('---countB', await counterB.methods.count().call());
    assert.equal(parseInt(await counterB.methods.count().call()), countB)
}

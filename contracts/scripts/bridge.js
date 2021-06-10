const fs = require('fs');
const Web3 = require('web3');
const rlp = require('rlp');
const { GetProof, VerifyProof } = require('eth-proof');
const {
    buffer2hex,
    getHeader,
    getReceiptLight,
    getReceipt,
    getReceiptRlp,
    getReceiptTrie,
    hex2key,
    index2key,
    getReceiptProof,
    getTransactionProof,
    getAccountProof,
    getStorageProof,
    getKeyFromProof,
} = require('../contracts/test/utils');

const yargs = require('yargs/yargs')
const { hideBin } = require('yargs/helpers')
const argv = yargs(hideBin(process.argv))
    .option('source', {
        type: 'string',
        description: 'URL for source chain'
    })
    .option('target', {
        type: 'string',
        description: 'URL for target chain'
    })
    .option('targetProver', {
        type: 'string',
        description: 'address of target prover contract'
    })
    .option('targetBridge', {
        type: 'string',
        description: 'address of target bridge contract'
    })
    .option('targetAccount', {
        type: 'string',
        description: 'account to send ETH to'
    })
    .option('privateKey', {
        type: 'string',
        description: 'privateKey'
    })
    .option('value', {
        type: 'string',
        description: 'value (WEI) to send'
    })
    .argv

console.log('--argv', argv);
const { source, target, targetProver, targetBridge, targetAccount, privateKey, value } = argv;

const web3source = new Web3(source);
const web3target = new Web3(target);
// TODO better yargs
const sourceHTTP = source.replace('ws', 'http').replace('8546', '8545');
const getProof = new GetProof(sourceHTTP);

sendAndVerify();

async function sendAndVerify() {
    let prover;

    const account = web3source.eth.accounts.privateKeyToAccount(privateKey);
    web3source.eth.accounts.wallet.add(account);
    web3source.eth.defaultAccount = account.address;
    web3target.eth.accounts.wallet.add(account);
    web3target.eth.defaultAccount = account.address;

    if (targetProver) prover = initProver(web3target, targetProver);
    else if (targetBridge) {
        prover = await deployProver(web3target, targetBridge);
    } else {
        throw new Error('Prover not found and cannot be deployed.')
    }

    // console.log('----3330333')
    // await stateChangeAndVerify(web3source, getProof, prover);
    // return;

    const receipt = await send(web3source, targetAccount, value);
    console.log('---sent ETH', value);
    const receiptproof = await getReceiptProof(getProof, prover, receipt.transactionHash);

    console.log('------receiptproof', receiptproof);

    const txproof = await getTransactionProof(getProof, prover, receipt.transactionHash);

    console.log('------txproof', txproof);

    // const isValid = await verifyProof(web3target, prover, receiptproof);

    const header = await web3source.eth.getBlock(receipt.blockNumber);

    console.log('------header', header);

    const isValid = await verifyBalance(web3target, prover, header, receiptproof, txproof, value);
    console.log(`Proof is valid: ${isValid}`);
}

function verifyBalance(web3, prover, header, receiptproof, txproof, value) {
    console.log('--------Verifying Proof:--------');
    // console.log(prover.methods.verifyBalance(header, receiptproof, txproof).encodeABI());
    console.log('--------verifying ... ---------');
    return prover.methods.verifyBalance(header, txproof, receiptproof, value).call({
        from: web3.eth.defaultAccount,
        gas: 8000000,
        price: 1,
    });
}

function verifyProof(web3, prover, data) {
    console.log('--------Verifying Proof:---------');
    console.log(prover.methods.verifyTrieProof(data).encodeABI());
    console.log('--------verifying ... ---------');
    return prover.methods.verifyTrieProof(data).call({
        from: web3.eth.defaultAccount,
        gas: 8000000,
        price: 1,
    });
}

function send(web3, target, value) {
    return web3.eth.sendTransaction({
        from: web3.eth.defaultAccount,
        to: target,
        value,
        gas: 50000,
        gasPrice: 1,
    })
    .on('error', function (error) { console.error('send ETH error', error) })
    .on('transactionHash', function(transactionHash) { console.log('Sending ETH:', transactionHash) })
    .on('receipt', function(receipt){
       console.log(`${target} was sent ${value} ${receipt.transactionHash}`);
    });
}

function initProver(web3, address) {
    const jsonObj = JSON.parse(fs.readFileSync('../contracts/build/contracts/Prover.json', 'utf8'));
    return new web3.eth.Contract(jsonObj.abi, address);
}

async function deployProver(web3, targetBridge) {
    const jsonObj = JSON.parse(fs.readFileSync('../contracts/build/contracts/Prover.json', 'utf8'));
    const prover = new web3.eth.Contract(jsonObj.abi);
    return prover.deploy({
        data: jsonObj.bytecode,
        arguments: [targetBridge],
    })
    .send({
        from: web3.eth.defaultAccount,
        gas: 6000000,
        gasPrice: '1'
    })
    .on('error', function (error) { console.error('deployProver error', error) })
    .on('transactionHash', function(transactionHash) { console.log('Tx sent:', transactionHash) })
    .on('receipt', function(receipt) {
       console.log('Prover address: ', receipt.contractAddress);
    });
}


async function stateChangeAndVerify(web3, getProof, prover) {
    const jsonObj = JSON.parse(fs.readFileSync('../contracts/build/contracts/Counter.json', 'utf8'));
    const counterFactory = new web3.eth.Contract(jsonObj.abi);
    console.log('---------eeeee-------')
    const counter = await counterFactory.deploy({
        data: jsonObj.bytecode,
        arguments: [],
    }).send({
        from: web3.eth.defaultAccount,
        gas: 6000000,
        gasPrice: 1,
    })
    .on('error', function (error) { console.error('counter error', error) })
    .on('transactionHash', function(transactionHash) { console.log(' counterTx sent:', transactionHash) })
    .on('receipt', function(receipt) {
       console.log('counter address: ', receipt.contractAddress);
    });
    console.log('---------ddddd-------')
    const receipt = await counter.methods.incrementCounter(2).send({
        from: web3.eth.defaultAccount,
        gas: 100000,
        gasPrice: 1,
    });

    const storageAddress = '0x0000000000000000000000000000000000000000000000000000000000000000';
    console.log('------55555', counter.options.address)
    // let proof;
    // try {
    //     proof = await getProof.eth_getProof(counter.address, [storageAddress], receipt.blockNumber);
    //     proof = await web3.eth.getProof(counter.address, [storageAddress], receipt.blockNumber);
    // } catch (e) {
    //     console.log(typeof e, e, e.message);

    // }

    // console.log('------accountProof', proof);


    const header = await web3source.eth.getBlock(receipt.blockNumber);

    // console.log('------header', header);

    // const accountProof = [...proof.accountProof]
    //     .map(node => node.map(elem => buffer2hex(elem)));
    // const proof = {
    //     keyIndex: 0,
    //     proofIndex: 0,
    //     receiptData: accountProof[accountProof.length - 1],
    //     proof: accountProof,
    //     headerData: proof.header.toHex(),
    // }
    // const proofData = proof.proof.map(node => buffer2hex(rlp.encode(node)));
    // const block = await prover.methods.toBlockHeader(proof.headerData).call();
    // return {
    //     expectedRoot: block.stateRoot,
    //     key: index2key(web3.utils.soliditySha3(address)),
    //     proof: proofData,
    //     keyIndex: proof.keyIndex,
    //     proofIndex: proof.proofIndex,
    //     expectedValue: rlp.decode(proof.receiptData)[1],
    // }


    const accountProof = await getAccountProof(web3, getProof, prover, counter.options.address, receipt.blockHash);
    console.log('------accountProof', accountProof);

    const storageProof = await getStorageProof(getProof, prover, counter.options.address, storageAddress, receipt.blockHash);

    console.log('------storageProof', storageProof);



    console.log('--------Verifying Proof:--------');
    // console.log(prover.methods.verifyBalance(header, receiptproof, txproof).encodeABI());
    console.log('--------verifying ... ---------');
    const isValid = prover.methods.verifyStorage(header, accountProof, storageProof).call({
        from: web3.eth.defaultAccount,
        gas: 8000000,
        price: 1,
    });

    console.log(`Proof is valid: ${isValid}`);


    // // 0x060c020c080809060c020307050c0a05030a04000001090b010c06040f020f0b040c0f0b0e0e050f0f0504060c0d0e06040b0f040b0e0e01020a040c00000808
}
// 0x0a0003050a080b0e04070f0e0c0f0c060d0f080e02060a090d0e0a0204040e080d0c020c080406000e0b0900020b0a08080c0e00060f010f0600000a0f0d030f0708

// 0x0308090a0d0f0d00060e080f07090402050d060e0d0f0206030e0b060c08020e0e02010d0c010301020a0402030c0c08020a09050b080c0d0403080a0302080c

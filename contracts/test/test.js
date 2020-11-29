const EthereumClient = artifacts.require('LightClient.sol');
const Prover = artifacts.require('Prover.sol');
const Counter = artifacts.require('Counter.sol');
const CounterTest = artifacts.require('CounterTest.sol');
const rlp = require('rlp');
const { GetProof } = require('eth-proof');
const proofs = require('./data');
const {
    buffer2hex,
    expandkey,
    getHeader,
    getReceiptLight,
    getReceiptRlp,
    getReceiptTrie,
    index2key,
    getReceiptProof,
    getAccountProof,
    getTransactionProof,
} = require('../utils');

const getProof = new GetProof("https://ropsten.infura.io/v3/18559f1ef1204f62b3cd0aec5ae1ab82");

contract('EthereumClient', async accounts => {
    let prover, client, counter, countertest;
    const blockNumber = 1;

    it('deploy', async () => {
        client = await EthereumClient.deployed();
        prover = await Prover.deployed();
        counter = await Counter.deployed();
        countertest = await CounterTest.deployed();
    });

    it('rlp encoding', async () => {
        const data = proofs.receipt[2].proof[0];
        const encoded = buffer2hex(rlp.encode(data));
        const decoded = await prover.rlp2List(encoded);
        const encoded2 = await prover.encodeproof(data);
        assert.equal(encoded, encoded2);
        assert.sameMembers(data, decoded);

    });

    it('block hash', async () => {
        const block = await web3.eth.getBlock(blockNumber);
        const header = getHeader(block);
        assert.equal(buffer2hex(header.hash()), block.hash);
        const serialized = header.serialize();

        const data = await prover.getBlockRlpData(block);
        assert.equal(buffer2hex(serialized), data);

        const result = await prover.toBlockHeader.call(data);
        assert(result.parentHash == block.parentHash, "parentHash not equal");
        assert(result.sha3Uncles == block.sha3Uncles, "sha3Uncles not equal");
        assert(result.stateRoot  == block.stateRoot,  "stateRoot not equal");
        assert(result.transactionsRoot == block.transactionsRoot, "transactionsRoot not equal");
        assert(result.receiptsRoot == block.receiptsRoot, "receiptsRoot not equal");
        assert(result.difficulty == block.difficulty, "difficulty not equal");
        assert(result.number == block.number, "number not equal");
        assert(result.gasLimit == block.gasLimit, "gasLimit not equal");
        assert(result.gasUsed == block.gasUsed, "gasUsed not equal");
        assert(result.timestamp == block.timestamp, "timestamp not equal");
        assert(result.nonce.toString() == web3.utils.toBN(block.nonce).toString(), "nonce not equal");

        const hash = await prover.getBlockHash(block);
        assert.equal(hash, block.hash);
    });

    it('receipt rlp encoding', async () => {
        const block = await web3.eth.getBlock(blockNumber);
        const receipt = await web3.eth.getTransactionReceipt(block.transactions[0]);
        const receiptLight = getReceiptLight(receipt);
        const receiptTrie = await getReceiptTrie([receipt]);
        const receiptRoot = buffer2hex(receiptTrie.root);

        assert.equal(block.receiptsRoot, receiptRoot);

        const serialized = getReceiptRlp(receipt);
        const data = await prover.getReceiptRlpData(receiptLight);
        assert.equal(buffer2hex(serialized), data);
    });

    it('client - adding blocks', async () => {
        const block1 = await web3.eth.getBlock(1);
        const block2 = await web3.eth.getBlock(2);
        const block3 = await web3.eth.getBlock(3);
        await client.addBlocks([block1, block2, block3]);

        const hash1 = await client.getBlockHash(1);
        const hash2 = await client.getBlockHash(2);
        const hash3 = await client.getBlockHash(3);
        assert.equal(hash1, block1.hash);
        assert.equal(hash2, block2.hash);
        assert.equal(hash3, block3.hash);
    });

    describe('receipt trie', function() {
        proofs.receipt.forEach((proof, i) => {
          it('receipt trie ' + i, async function() {
            const proofData = proof.proof.map(node => buffer2hex(rlp.encode(node)));
            const block = await prover.toBlockHeader.call(proof.headerData);
            const data = {
                expectedRoot: block.receiptsRoot,
                key: index2key(proof.receiptIndex, proof.proof.length),
                proof: proofData,
                keyIndex: proof.keyIndex,
                proofIndex: proof.proofIndex,
                expectedValue: proof.receiptData,
            }
            const response = await prover.verifyTrieProof(data);
            assert.equal(response, true);
          });
        });
    });

    it('verify receipt proof from chain', async () => {
        const txhash = '0x3baef8672605d65265accd178796cc460e5f9248c083cd2577d95c432f74f6e7';
        const proof = await getReceiptProof(getProof, prover, txhash);
        const response = await prover.verifyTrieProof(proof);
        assert.equal(response, true);
    });

    it('verify balance proof from chain', async () => {
        const txhash = '0x64e0262b607b9c3eedac0b070e9096123ac13003ea152a66e7cd2856e64785e9'
        const value = web3.utils.toWei('4.999097');
        // const receiptProof = await getReceiptProof(getProof, prover, txhash);
        // const txProof = await getTransactionProof(getProof, prover, txhash);
        const receiptProof = proofs.balance.receipt;
        const txProof = proofs.balance.transaction;
        const header = proofs.balance.header;

        await client._addBlock(header);
        const response = await prover.verifyBalance(header, txProof, receiptProof, value);
        assert.equal(response, true);
    });

    it('verify account proof', async () => {
        const storageAddress = '0x0000000000000000000000000000000000000000000000000000000000000000';
        const data = proofs.account2;
        const expectedValue = rlp.decode(data.accountProof[data.accountProof.length - 1])[1];
        const accountProof = {
            expectedRoot: data.header.stateRoot,
            key: '0x' + expandkey(web3.utils.soliditySha3(data.address)),
            proof: data.accountProof,
            keyIndex: 0,
            proofIndex: 0,
            expectedValue: buffer2hex(expectedValue),
        }
        const ind = 0;
        const kkkey = '0x' + data.storageProof[ind].key.substring(2).padStart(64, '0');
        const storageProof = {
            expectedRoot: data.storageHash,
            key: '0x' + expandkey(web3.utils.soliditySha3(kkkey)),
            proof: data.storageProof[ind].proof,
            keyIndex: 0,
            proofIndex: 0,
            expectedValue: data.storageProof[ind].value,
        }
        const header = data.header;

        await client._addBlock(data.header);
        const response = await prover.verifyStorage(header, accountProof, storageProof);
        assert.equal(response, true);
    });

    it.skip('verify Counter same chain (mimic two chains)', async () => {
        let receipt;
        const _getProof = new GetProof("http://127.0.0.1:8645");
        const address = accounts[2];
        await web3.eth.personal.unlockAccount(address, "0", 60000);

        let counterA = (await countertest.count()).toNumber();
        let counterB = (await countertest.count2()).toNumber();

        // Send transaction on Chain A
        receipt = await countertest.incrementCounter(3, {from: address});
        counterA += 3;
        assert.equal(counterA, (await countertest.count()).toNumber());
        const header = await web3.eth.getBlock(receipt.receipt.blockNumber);
        const accountProof = await getAccountProof(web3, _getProof, prover, address, receipt.receipt.blockHash);
        const txProof = await getTransactionProof(_getProof, prover, receipt.receipt.transactionHash);
        const receiptProof = await getReceiptProof(_getProof, prover, receipt.receipt.transactionHash);

        // Forward transaction on Chain B
        await client._addBlock(header);
        receipt = await prover.forwardAndVerify(header, accountProof, txProof, receiptProof, address);

        counterB += 3;
        assert.equal(counterB, (await countertest.count2()).toNumber());
    });
});

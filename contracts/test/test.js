const EthereumClient = artifacts.require('EthereumClient');
const Prover = artifacts.require('Prover');
const rlp = require('rlp');
const ethblock = require('@ethereumjs/block');
const ethtx = require('@ethereumjs/tx');
const MPT = require('merkle-patricia-tree');
const {proofs} = require('./data');

const Trie = MPT.BaseTrie;

contract('EthereumClient', async accounts => {
    let instance, client;
    const blockNumber = 1;

    it('deploy', async () => {
        instance = await Prover.deployed();
        client = await EthereumClient.deployed();
    });

    it('rlp encoding', async () => {
        const data = proofs[2].proof[0];

        const encoded = buffer2hex(rlp.encode(data));
        const decoded = await instance.rlp2List(encoded);
        const encoded2 = await instance.encodeproof(data);
        assert.equal(encoded, encoded2);
        assert.sameMembers(data, decoded);

    });

    it('block hash', async () => {
        const block = await web3.eth.getBlock(blockNumber);
        const header = getHeader(block);
        assert.equal(buffer2hex(header.hash()), block.hash);
        const serialized = header.serialize();

        const data = await instance.getBlockRlpData(block);
        assert.equal(buffer2hex(serialized), data);

        const result = await instance.toBlockHeader.call(data);
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

        const hash = await instance.getBlockHash(block);
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
        const data = await instance.getReceiptRlpData(receiptLight);
        assert.equal(buffer2hex(serialized), data);
    });

    it('client - adding blocks', async () => {
        const block1 = await web3.eth.getBlock(1);
        const block2 = await web3.eth.getBlock(2);
        const block3 = await web3.eth.getBlock(3);
        await client.addBlock(block1);
        await client.addBlock(block2);
        await client.addBlock(block3);

        const hash1 = await client.getBlockHash(1);
        const hash2 = await client.getBlockHash(2);
        const hash3 = await client.getBlockHash(3);
        assert.equal(hash1, block1.hash);
        assert.equal(hash2, block2.hash);
        assert.equal(hash3, block3.hash);

        // await client.addBlock(await web3.eth.getBlock(4));
    });

    describe('receipt trie', function() {
        proofs.forEach((proof, i) => {
          it('receipt trie ' + i, async function() {
            const proofData = proof.proof.map(node => buffer2hex(rlp.encode(node)));
            const block = await instance.toBlockHeader.call(proof.headerData);
            const data = {
                expectedRoot: block.receiptsRoot,
                key: index2key(proof.receiptIndex, proof.proof.length),
                proof: proofData,
                keyIndex: proof.keyIndex,
                proofIndex: proof.proofIndex,
                expectedValue: proof.receiptData,
            }
            const response = await instance.verifyTrieProof(data);
            assert.equal(response, true);
          });
        });
    });

    it.skip('verify trie proof', async () => {

        const trie = new Trie();
        await trie.put(Buffer.from('test1'), Buffer.from('one1'))
        await trie.put(Buffer.from('test2'), Buffer.from('one2'))
        await trie.put(Buffer.from('test3'), Buffer.from('one3'))
        await trie.put(Buffer.from('test4'), Buffer.from('one4'))

        var temp1 = await trie.findPath(Buffer.from('test1'))
        console.log('--findPath', temp1);

        var node1 = await trie._lookupNode(Buffer.from(temp1.node._branches[3]))
        console.log('Branch node 1 hash: ', node1)


        // const proof = await Trie.createProof(trie, Buffer.from('test1'))

        // console.log('proof', proof);

        // const value = await Trie.verifyProof(trie.root, Buffer.from('test1'), proof)
        // console.log(value.toString()) // 'one'


    });
});

function buffer2hex(buffer) {
    return '0x' + buffer.toString('hex');
}

function getHeader(block) {
    const headerData = {
        number: block.number,
        parentHash: block.parentHash,
        difficulty: parseInt(block.difficulty),
        gasLimit: block.gasLimit,
        timestamp: block.timestamp,
        mixHash: block.mixHash,
        nonce: block.nonce,
        uncleHash: block.sha3Uncles,
        bloom: block.logsBloom,
        transactionsTrie: block.transactionsRoot,
        stateRoot: block.stateRoot,
        receiptTrie: block.receiptsRoot,
        coinbase: block.miner,
        extraData: block.extraData,
        gasUsed: block.gasUsed,
        // totalDifficulty: block.totalDifficulty,
        // size: block.size,
    }
    const header = ethblock.BlockHeader.fromHeaderData(headerData);
    // console.log('----', header.toJSON());
    return header;
}

function getReceiptLight(receipt) {
    return {
        status: receipt.status ? 1 : 0,
        gasUsed: receipt.gasUsed,
        logsBloom: receipt.logsBloom,
        logs: receipt.logs,
    }
}

function getReceipt(receipt) {
    // const receiptData = {
    //     transactionHash: receipt.transactionHash,
    //     transactionIndex: receipt.transactionIndex,
    //     blockHash: receipt.blockHash,
    //     blockNumber: receipt.blockNumber,
    //     from: receipt.from,
    //     to: receipt.to,
    //     gasUsed: receipt.gasUsed,
    //     cummulativeGasUsed: receipt.cummulativeGasUsed,
    //     contractAddress: receipt.contractAddress,
    //     // bloom: receipt.logsBloom,
    //     // status: receipt.status,
    //     // v: receipt.v,
    //     // r: receipt.r,
    //     // s: receipt.s,
    //     // logs: receipt.logs,
    // }
    const receiptData = {
        status: receipt.status ? 1 : 0,
        gasUsed: receipt.gasUsed,
        bloom: receipt.logsBloom,
        logs: receipt.logs,
    }
    return receiptData;
}

function getReceiptRlp(receipt) {
    return rlp.encode(Object.values(getReceipt(receipt)));
}

async function getReceiptTrie(receipts) {
    const receiptTrie = new Trie();
    for (let txIdx = 0; txIdx < receipts.length; txIdx++) {
        await receiptTrie.put(rlp.encode(txIdx), getReceiptRlp(receipts[txIdx]));
    }
    return receiptTrie;
}

function index2key(index, proofLength) {
    const actualkey = [];
    const encoded = buffer2hex(rlp.encode(index)).slice(2);
    let key = [...new Array(encoded.length / 2).keys()].map(i => parseInt(encoded[i * 2] + encoded[i * 2 + 1], 16));

    key.forEach(val => {
        if (actualkey.length + 1 === proofLength) {
            actualkey.push(val);
        } else {
            actualkey.push(Math.floor(val / 16));
            actualkey.push(val % 16);
        }
    });
    return '0x' + actualkey.map(v => v.toString(16).padStart(2, '0')).join('');
}

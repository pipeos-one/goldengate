const EthereumClient = artifacts.require('EthereumClient');
const Prover = artifacts.require('Prover');
const rlp = require('rlp');
const ethblock = require('@ethereumjs/block');
const ethtx = require('@ethereumjs/tx');
const MPT =require('merkle-patricia-tree');

const Trie = MPT.BaseTrie;

contract('EthereumClient', async accounts => {
    let instance, client;
    const blockNumber = 1;

    it('deploy', async () => {
        instance = await Prover.deployed();
        client = await EthereumClient.deployed();
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

    it('receipt trie', async () => {
        const headerData = '0xf9021aa0f779e50b45bc27e4ed236840e5dbcf7afab50beaf553be56bf76da977e10cc73a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d493479452bc44d5378309ee2abf1539bf71de1b7d7be3b5a014c996b6934d7991643669e145b8355c63aa02cbde63d390fcf4e6181d5eea45a079b7e79dc739c31662fe6f25f65bf5a5d14299c7a7aa42c3f75b9fb05474f54ca0e28dc05418692cb7baab7e7f85c1dedb8791c275b797ea3b1ffcaec5ef2aa271b9010000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000010000000000000000000000000000000000000000000000000000000408000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000010000000000000000000000000000000000000000000000000000000400000000000100000000000000000000000000080000000000000000000000000000000000000000000100002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000903234373439353837313930323034343383890fe68395ba8e82d0d9845dd84a079150505945206e616e6f706f6f6c2e6f7267a0a35425f443452cf94ba4b698b00fd7b3ff4fc671dea3d5cc2dcbedbc3766f45e88af7fec6031063a17';

        const receiptData = '0xf901a60182d0d9b9010000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000010000000000000000000000000000000000000000000000000000000408000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000010000000000000000000000000000000000000000000000000000000400000000000100000000000000000000000000080000000000000000000000000000000000000000000100002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000f89df89b94dac17f958d2ee523a2206206994597c13d831ec7f863a0ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3efa00000000000000000000000006cc5f688a315f3dc28a7781717a9a798a59fda7ba00000000000000000000000007e7a32d9dc98c485c489be8e732f97b4ffe3a4cda000000000000000000000000000000000000000000000000000000001a13b8600'

        const logEntry = '0xf89b94dac17f958d2ee523a2206206994597c13d831ec7f863a0ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3efa00000000000000000000000006cc5f688a315f3dc28a7781717a9a798a59fda7ba00000000000000000000000007e7a32d9dc98c485c489be8e732f97b4ffe3a4cda000000000000000000000000000000000000000000000000000000001a13b8600'

        const proof = [
            [
                '0x2080',
                '0xf901a60182d0d9b9010000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000010000000000000000000000000000000000000000000000000000000408000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000010000000000000000000000000000000000000000000000000000000400000000000100000000000000000000000000080000000000000000000000000000000000000000000100002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000f89df89b94dac17f958d2ee523a2206206994597c13d831ec7f863a0ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3efa00000000000000000000000006cc5f688a315f3dc28a7781717a9a798a59fda7ba00000000000000000000000007e7a32d9dc98c485c489be8e732f97b4ffe3a4cda000000000000000000000000000000000000000000000000000000001a13b8600'
            ]
        ]
// 822080b901a9 ; 0x2080
        const proofData = proof.map(node => buffer2hex(rlp.encode(node)));

        const receiptIndex = 0;
        const keyIndex = 0;
        const proofIndex = 0;
        const block = await instance.toBlockHeader.call(headerData);

        const response = await instance.verifyTrieProof(
            block.receiptsRoot,
            rlp.encode(receiptIndex),
            proofData,
            keyIndex,
            proofIndex,
            receiptData,
        );
        console.log('response', response);
    });

    it.skip('receipt trie', async () => {
        const headerData = 'f9021aa0fbc31be764b2ba0eb7ee8ac2ce71743a9643772960eca29751c014e21de21278a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347945a0b54d5dc17e0aadc383d2db43b0a0d3e029c4ca0f35ea6f9f8a4a6bd6338ded9e4835c5111e3de7d78ec3869bba35e8db64f98a1a03990dcdacdec9c2626acb9b7c45c4fb5ddf62e61fd03151940f459da6f995345a0b23d76b7b3747e862bb148796a84697aed7ae4f493bdc6e8fd86fabc15c2076cb9010020e29a9a88c12d9ce049f610e00016230089010014ada31c62437913062aabdc310b8558216215f4045742123241a30d963087246804068307c1514017e839815c000020829cdc00eb84d10f87c0dd384d83a502822ae0289b28b40dc845307c536088a1125242c00788626840062910dd4e183418a2411c0ca1d412e0709cc70339c0052345e08920a15e05a6c264b10808375949a20c6ec6ce016204b50011077da58a0ac92e5a1e07a486512fb332d1239dd5e85890e0005863101c9108651430a0e300090a00945b4d13876310242804da061c2d149008910001340c61004c113565f1321cde85a24c3cf27dfa4450c84010d01156d0084fb4350886a8ea9032323433303231373839313735313932839a1acc839895ff839848c0845ec4709a906574682d70726f2d687a682d74303032a00bdd7eaec7aa518470d8fc2c9c3ce9b20ae81cbd6e9a7697e7b6955eafbe71448825e70b4c039f477c';

        const receiptData = 'f901a70183012d99b9010000000000000000000000000000000000000001000000000000000000000000000000000000000000000002000000010000000000000000000000000000000000000000000008000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000400000000000000000000000000000000000000000000000000100000000000000000000004000080000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f89df89b94dac17f958d2ee523a2206206994597c13d831ec7f863a0ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3efa0000000000000000000000000adb2b42f6bd96f5c65920b9ac88619dce4166f94a0000000000000000000000000658a36d8f840f73207af8df717d12046b2c75969a000000000000000000000000000000000000000000000000000000000042c1d80'

        const logEntry = 'f89b94dac17f958d2ee523a2206206994597c13d831ec7f863a0ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3efa0000000000000000000000000adb2b42f6bd96f5c65920b9ac88619dce4166f94a0000000000000000000000000658a36d8f840f73207af8df717d12046b2c75969a000000000000000000000000000000000000000000000000000000000042c1d80'

        const proof = [
            [
                "7ea815c3bb71385b7a510e4982f8313c587df3e089ff5f10ef0b56c36071181a",
                "aed4d27efd05e63eef759ea509eab454e0af48bee830df3e35555bb0a286d231",
                "33e390a966c516979815c1f2017dbbced85a051ee1fa80f3e1ec53cf1c9cdd2a",
            ]
        ]
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

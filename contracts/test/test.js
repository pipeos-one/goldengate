const EthereumClient = artifacts.require('LightClient.sol');
const Prover = artifacts.require('Prover.sol');
const Counter = artifacts.require('Counter.sol');
const CounterTest = artifacts.require('CounterTest.sol');
const LightClientMock = artifacts.require('LightClientMock.sol');
const ProverStateSync = artifacts.require('ProverStateSync.sol');
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
} = require('../scripts/utils');

const getProof = new GetProof("https://ropsten.infura.io/v3/" + process.env.INFURA_TOKEN);

contract('EthereumClient', async accounts => {
    let prover, client, counter;
    let proverStateSync;
    const blockNumber = 1;

    it('deploy', async () => {
        counter = await Counter.new();
        const block = await web3.eth.getBlock(0);
        client = await EthereumClient.new(3, 10, 3, block);
        clientmock = await LightClientMock.new();
        prover = await Prover.new(clientmock.address);
        proverStateSync = await ProverStateSync.new(clientmock.address);
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

    it('receipt logs RLP encoding/decoding', async () => {
        let proof = proofs.receipt[0];
        const log = await prover.toReceiptLog(proof.logEntry);
        assert.equal(log.contractAddress, '0xdAC17F958D2ee523a2206206994597C13D831ec7');
        assert.equal(log.data, '0x00000000000000000000000000000000000000000000000000000001a13b8600');
        assert.sameMembers(log.topics, [
            '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef',
            '0x0000000000000000000000006cc5f688a315f3dc28a7781717a9a798a59fda7b',
            '0x0000000000000000000000007e7a32d9dc98c485c489be8e732f97b4ffe3a4cd',
        ]);
        assert.equal(await prover.getLog(log), proof.logEntry);

        const receipt = await prover.toReceipt(proof.receiptData);
        assert.equal(receipt.logs.length, 1);
        assert.deepEqual(receipt.logs[0], log);
    });

    it('client - adding blocks', async () => {
        // 19 blocks
        let header;
        const block1 = await web3.eth.getBlock(1);
        const block2 = await web3.eth.getBlock(2);
        const block3 = await web3.eth.getBlock(3);
        const block4 = await web3.eth.getBlock(4);
        const block5 = await web3.eth.getBlock(5);
        const block6 = await web3.eth.getBlock(6);
        const block7 = await web3.eth.getBlock(7);
        const block8 = await web3.eth.getBlock(8);
        const block9 = await web3.eth.getBlock(9);
        const block10 = await web3.eth.getBlock(10);
        const block11 = await web3.eth.getBlock(11);
        const block12 = await web3.eth.getBlock(12);
        const proposal1 = [block1, block2, block3];
        const proposal2 = proposal1.concat([block4, block5, block6, block7]);
        const proposal3 = proposal2.concat([block8, block9, block10, block11]);
        const proposal4 = proposal3.slice(4).concat([block12]);

        assert.equal(await client.getLastConfirmed(), 0);
        assert.equal(await client.getLastVerifiable(), 0);

        await client.addBlocks(proposal1);
        header = await client.lastHeader();
        assert.equal(header.hash, block3.hash);
        assert.equal(header.parentHash, block3.parentHash);
        assert.equal(header.number, block3.number);
        assert.equal(await client.getBlockHash(block1.number), block1.hash);
        assert.equal(await client.getBlockHash(block2.number), block2.hash);
        assert.equal(await client.getBlockHash(block3.number), block3.hash);
        assert.equal(await client.getLastConfirmed(), 0);
        assert.equal(await client.getLastVerifiable(), 0);

        receipt = await client.addBlocks(proposal2);
        header = await client.lastHeader();
        assert.equal(header.hash, block7.hash);
        assert.equal(header.parentHash, block7.parentHash);
        assert.equal(header.number, block7.number);
        assert.equal(await client.getBlockHash(block1.number), block1.hash);
        assert.equal(await client.getBlockHash(block2.number), block2.hash);
        assert.equal(await client.getBlockHash(block3.number), block3.hash);
        assert.equal(await client.getBlockHash(block4.number), block4.hash);
        assert.equal(await client.getBlockHash(block5.number), block5.hash);
        assert.equal(await client.getBlockHash(block6.number), block6.hash);
        assert.equal(await client.getBlockHash(block7.number), block7.hash);

        assert.equal(await client.getLastConfirmed(), 0);
        assert.equal(await client.getLastVerifiable(), 0);

        await client.tick();
        await client.tick();
        await client.tick();
        await client.tick();
        assert.equal(await client.getLastConfirmed(), 4);

        await expectFailure(client.addBlocks(proposal3), "Invalid number of blocks", "Proposal3 should have failed");

        await client.updateLastVerifiableHeader(block4);
        assert.equal(await client.getLastVerifiable(), 4);

        receipt = await client.addBlocks(proposal4);
        header = await client.lastHeader();
        assert.equal(header.hash, block12.hash);
        assert.equal(header.parentHash, block12.parentHash);
        assert.equal(header.number, block12.number);
        assert.equal(await client.getBlockHash(block1.number), block1.hash);
        assert.equal(await client.getBlockHash(block2.number), block2.hash);
        assert.equal(await client.getBlockHash(block3.number), block3.hash);
        assert.equal(await client.getBlockHash(block4.number), block4.hash);
        assert.equal(await client.getBlockHash(block5.number), block5.hash);
        assert.equal(await client.getBlockHash(block6.number), block6.hash);
        assert.equal(await client.getBlockHash(block7.number), block7.hash);
        assert.equal(await client.getBlockHash(block8.number), block8.hash);
        assert.equal(await client.getBlockHash(block9.number), block9.hash);
        assert.equal(await client.getBlockHash(block10.number), block10.hash);
        assert.equal(await client.getBlockHash(block11.number), block11.hash);
        assert.equal(await client.getBlockHash(block12.number), block12.hash);
        assert.equal(await client.getLastConfirmed(), 4);
        assert.equal(await client.getLastVerifiable(), 4);
    });

    it('prover - verify header', async () => {
        let result;
        const header = await web3.eth.getBlock(1);

        result = await prover.verifyHeader(header);
        assert.equal(result.valid, false);

        await clientmock._addBlock(header);
        result = await prover.verifyHeader(header);
        assert.equal(result.valid, true);
        assert.equal(await prover.getBlockHash(header), header.hash);

        result = await prover.verifyHeader({...header, number: 4})
        assert.equal(result.valid, false);
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
            let response = await prover.verifyTrieProof(data);
            assert.equal(response, true);

            response = await prover.verifyLog(data, proof.logEntry, 0);
            assert.equal(response.valid, true);

            const log = await prover.toReceiptLog(proof.logEntry);
            const changedEntry = await prover.getLog({
                ...log,
                contractAddress: '0x20A6284411E6A327F3b2eF5E5931745A239F6F97',
            });
            response = await prover.verifyLog(data, changedEntry, 0);
            assert.equal(response.valid, false);
          });
        });
    });

    it('verify receipt proof from chain', async () => {
        const txhash = '0x3baef8672605d65265accd178796cc460e5f9248c083cd2577d95c432f74f6e7';
        const proof = await getReceiptProof(getProof, prover, txhash);
        const response = await prover.verifyTrieProof(proof);
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

        // let response = await prover.verifyHeader(header);
        // assert.equal(response.valid, false, response.reason);

        // await clientmock._addBlock(header);
        // response = await prover.verifyHeader(header);
        // assert.equal(response.valid, true, response.reason);

        response = await prover.verifyAccount(header, accountProof);
        assert.equal(response.valid, true, response.reason);

        response = await prover.verifyStorage(accountProof, storageProof);
        assert.equal(response.valid, true, response.reason);
    });

    it.skip('verify Counter same chain (mimic two chains) --network geth', async () => {
        let receipt;
        const _getProof = new GetProof("http://127.0.0.1:8645");
        const address = accounts[2];
        const countertest = await CounterTest.new(proverStateSync.address);
        await web3.eth.personal.unlockAccount(address, "0", 60000);

        let counterA = (await countertest.count()).toNumber();
        let counterB = (await countertest.count2()).toNumber();

        // Send transaction on Chain A
        receipt = await countertest.incrementCounter(3, {from: address});
        counterA += 3;
        assert.equal(counterA, (await countertest.count()).toNumber());
        const header = await web3.eth.getBlock(receipt.receipt.blockNumber);
        const accountProof = await getAccountProof(web3, _getProof, proverStateSync, address, receipt.receipt.blockHash);
        const txProof = await getTransactionProof(_getProof, proverStateSync, receipt.receipt.transactionHash);
        const receiptProof = await getReceiptProof(_getProof, proverStateSync, receipt.receipt.transactionHash);

        // Forward transaction on Chain B
        await clientmock._addBlock(header);
        receipt = await proverStateSync.forwardAndVerify(header, accountProof, txProof, receiptProof, address);

        counterB += 3;
        assert.equal(counterB, (await countertest.count2()).toNumber());
    });
});

async function expectFailure(promise, errorMessage, successMessage) {
    receipt = await promise.catch(e => {
        assert.equal(e.message.includes(errorMessage), true);
    });
    expect(receipt, successMessage).to.be.undefined;
}

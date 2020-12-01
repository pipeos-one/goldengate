const fs = require('fs');
const Web3 = require('web3');

const yargs = require('yargs/yargs')
const { hideBin } = require('yargs/helpers')
const {fullToMin} = require('./utils');


const argv = yargs(hideBin(process.argv))
    .option('source', {
        type: 'string',
        description: 'URL for source chain'
    })
    .option('target', {
        type: 'string',
        description: 'URL for target chain'
    })
    .option('targetContract', {
        type: 'string',
        description: 'Address of target bridge contract'
    })
    .option('startBlock', {
        type: 'number',
        description: 'Block at which to start syncing if a new LightClient contract is deployed'
    })
    .option('privateKey', {
        type: 'string',
        description: 'privateKey'
    })
    .default('startBlock', 0)
    .argv

console.log('--argv', argv);
const { source, target, targetContract, privateKey, startBlock } = argv;

const web3source = new Web3(source);
const web3target = new Web3(target);

relay();

async function relay() {
    let client;

    const account = web3source.eth.accounts.privateKeyToAccount(privateKey);
    web3source.eth.accounts.wallet.add(account);
    web3source.eth.defaultAccount = account.address;
    web3target.eth.accounts.wallet.add(account);
    web3target.eth.defaultAccount = account.address;

    if (targetContract) client = initBridge(web3target, targetContract);
    else {
        const initBlock = await web3source.eth.getBlock(startBlock)
        client = await deployBridge(web3target, initBlock);
    }

    const minNumberBlocks = parseInt(await client.methods.minNumberBlocks().call());
    let maxNumberBlocks = parseInt(await client.methods.maxNumberBlocks().call());
    const registerPeriod = parseInt(await client.methods.registerPeriod().call());
    let blockPool = [];
    let lastValidBlockSent;

    console.log('minNumberBlocks', minNumberBlocks);
    console.log('maxNumberBlocks', maxNumberBlocks);
    console.log('registerPeriod', registerPeriod);
    maxNumberBlocks = 10;

    await catchup();

    async function catchup() {
        console.log('------------------------------catchup---------------------------');
        blockPool = [];
        const lastValidBlock = await client.methods.lastValidBlock().call();
        const lastBlock = await client.methods.lastBlock().call();
        const lastBlockNumber =  parseInt(lastBlock.number);
        const lvbn = parseInt(lastValidBlock.number);
        console.log('----------- lastValidBlock', lvbn);
        console.log('----------- lastBlock', lastBlockNumber);
        const block = parseInt((await web3source.eth.getBlock('latest')).number);
        console.log('remaining', block - lastBlockNumber);
        // +1 - we include the last valid block
        const maxBlocks = Math.min(block - lastBlockNumber, maxNumberBlocks);
        const iter = [...new Array(maxBlocks).keys()];
        for(let number of iter) {
            number = lvbn + number + 1;  // don't add the last valid block
            const block = await web3source.eth.getBlock(number);
            blockPool.push(block);
        }

        console.log('blockPool', blockPool.length);

        if (blockPool.length >= minNumberBlocks) {
            await tryAddBlocks(lastValidBlock).catch(console.log);
            catchup();
        }
    }

    async function tryUpdateValidBlock(lastAddedBlock) {
        const blocktick = parseInt(await client.methods.blockTick().call());
        const lastb = parseInt((await client.methods.lastBlock().call()).number);
        // const ladded = parseInt(lastAddedBlock.number);
        const padd = 2;
        // console.log('tryUpdateValidBlock', blocktick, (lastb - registerPeriod - padd), blocktick > (lastb - registerPeriod - padd));
        if (blocktick > (lastb - registerPeriod - padd)) {
            console.log('--tryUpdateValidBlock: ', blocktick);
            const block = await web3source.eth.getBlock(blocktick);
            await client.methods.updateLastValidBlock(block).send({
                from: web3target.eth.defaultAccount,
                gas: 8000000,
                gasPrice: 1,
            })
            .then(receipt => {
                console.log(`%%%%%% tryUpdateValidBlock: ${receipt.transactionHash}`)
                console.log('logs', Object.keys(receipt.events));
            });
        }
    }

    async function tryAddBlocks(lastValidBlock) {
        lastValidBlock = await client.methods.lastValidBlock().call();
        // console.log('tryAddBlocks', lastValidBlock.number);

        const lvbn = parseInt(lastValidBlock.number);

        const lastBlock = parseInt((await client.methods.lastBlock().call()).number);
        console.log('lastValidBlockSent', lastValidBlockSent, lvbn);
        if (lastValidBlockSent >= lvbn) return;

        if (blockPool.length === 0) return;

        const headers = blockPool.slice(
            0,
            maxNumberBlocks,
        );

        console.log(`blockPool: ${blockPool.length} ; header: ${headers.length} ; ${headers.length ? headers[0].number : null} - ${headers.length ? headers[headers.length - 1].number : null}`);

        // race condition when this is triggered on old data, where last valid block is old
        // try again next time
        if (lvbn > headers[0].number) return;


        if (headers.length < minNumberBlocks) return;
        if (headers.length > maxNumberBlocks) return;
        if (lastBlock > headers[headers.length - 1].number) {
            console.log(`Last block ${lastBlock} on chain > ${headers[headers.length - 1].number} what we are sending`);
            return;
        }

        console.log(`********** Adding ${headers.length} blocks ${headers[0].number} -> ${headers[headers.length - 1].number}`);
        return addBlocks(web3target, client, headers).then(() => {
            lastValidBlockSent = lvbn;
            blockPool = [];
            console.log('---empty blockPool---');
        }).catch(e => console.log('Adding blocks failed.', e));
    }

    // const subscriptionHeaders = web3source.eth.subscribe('newBlockHeaders', async function(error, headerData) {
    //     console.log('newBlockHeaders', headerData ? headerData.number : null);
    //     if (error || !headerData) {
    //         console.error('subscription error', error);
    //         return;
    //     }

    //     blockPool.push(headerData);
    //     tryAddBlocks();

    //     // addBlock(web3target, client, headerData).then(() => {
    //     //     subscriptionHeaders.unsubscribe();
    //     // });


    // });

    const intervalid = setInterval(async () => {
        const lastb = parseInt((await client.methods.lastBlock().call()).number);
        const blocktick = parseInt(await client.methods.blockTick().call()) + registerPeriod;

        console.log('**tick', lastb, blocktick, lastb >= blocktick + registerPeriod);
        client.methods.tick().send({
            from: web3target.eth.defaultAccount,
            gas: 8000000,
            gasPrice: 1,
        })
        .then(receipt => {
            console.log(`%%%%% Tick: ${receipt.transactionHash}`, receipt.events.BlockAdded ?  receipt.events.BlockAdded.returnValues.number : null);
            // console.log('logs', Object.keys(receipt.events));

            if (receipt.events.BlockAdded) {
                tryUpdateValidBlock(receipt.events.BlockAdded.returnValues);
            }
        });
    }, 4000);

    const subscriptionClient = client.events.FinalBlockChanged(function(error, event) {
        if (error) {
            console.error('FinalBlockChanged error', error);
            return;
        }
        const {number, hash} = event.returnValues;
        console.log('FinalBlockChanged', event.returnValues);
        // tryAddBlocks({number, hash});  // if not catchup
    });

    client.events.BlockAdded(function(error, event) {
        if (error) {
            console.error('BlockAdded error', error);
            return;
        }
        console.log('***BlockAdded', event.returnValues);
        tryUpdateValidBlock(event.returnValues);
    });
}

function initBridge(web3, address) {
    const jsonObj = JSON.parse(fs.readFileSync('../build/contracts/LightClient.sol/LightClient.json', 'utf8'));
    return new web3.eth.Contract(jsonObj.abi, address);
}

async function deployBridge(web3, block) {
    const jsonObj = JSON.parse(fs.readFileSync('../build/contracts/LightClient.sol/LightClient.json', 'utf8'));
    const bridge = new web3.eth.Contract(jsonObj.abi);
    return bridge.deploy({
        data: jsonObj.bytecode,
        arguments: [6, 50, 6, fullToMin(block)],
    })
    .send({
        from: web3.eth.defaultAccount,
        gas: 8000000,
        gasPrice: 1,
    })
    .on('error', function (error) { console.error('deployBridge error', error) })
    .on('transactionHash', function(transactionHash){ console.log('Tx sent:', transactionHash) })
    .on('receipt', function(receipt) {
        console.log(`Deployed bridge with number & height: ${block.number}, ${block.hash}`);
        console.log('Address: ', receipt.contractAddress);
    });
}

function addBlocks(web3, client, headers) {
    return client.methods.addBlocks(headers)
        .send({
            from: web3.eth.defaultAccount,
            gas: 3000000,
            gasPrice: 1,
        })
        .then(receipt => {
            console.log(`%%%%%% Blocks added ${receipt.transactionHash}`)
            // console.log('logs', Object.keys(receipt.events));
        });
}

# Ethereum State Bridge

(in-work)
Bridge between two EVM-based chains.
See https://youtu.be/WD_2tuX9jeg


```

node relay.js --source=wss://ropsten.infura.io/ws/v3/2cd3efbd02a24a3ea799ea5be970446d --target=ws://127.0.0.1:8545 --startBlock 9175660 --privateKey=0xc526ee95bf44d8fc405a158bb884d9d1238d99f0612e9f33d006bb0789009aaa



node bridge.js --source=ws://192.168.1.140:8546 --target=ws://192.168.1.127:8546 --targetBridge=0xdB98227d7D83ee5EF03caE4B53617D7f4a32cca1 --targetProver=0xf37508E669e415Fd0a80ea1Fcd76A6C1C9d228be --targetAccount=0xac18baca4deadd329c1b90b6d576fb81357c0a11 --privateKey=45122bfb302c5e4bb63cf49a46863413557da04b1b5c4a9bdcf36dc728065fa5 --value 1000000000

```







```
clef init
clef newaccount

clef --keystore <GETH_LOCATION>/keystore --chainid 5

geth --dev --datadir ~/bridgetest --syncmode "full" --http --http.addr "192.168.1.140" --http.port 8645 --http.corsdomain "*" --http.vhosts "*" --ws --ws.addr "192.168.1.140" --ws.port 8646 --ws.origins "*" --http.api web3,eth,debug,personal,net --ws.api web3,eth,debug,personal,net --vmdebug --gcmode archive


--allow-insecure-unlock


--dev.period value


geth --dev --datadir ~/bridgetest --syncmode "full" --http --http.addr "127.0.0.1" --http.port 8645 --ws --ws.addr "127.0.0.1" --ws.port 8646 --http.api web3,eth,debug,personal,net --ws.api web3,eth,debug,personal,net --vmdebug --gcmode archive --rpc


geth --dev --datadir ~/bridgetest --syncmode "full" --http --http.addr "192.168.1.140" --http.port 8645 --ws --ws.addr "192.168.1.140" --ws.port 8646 --http.api web3,eth,debug,personal,net --ws.api web3,eth,debug,personal,net --vmdebug --gcmode archive --rpc

45122bfb302c5e4bb63cf49a46863413557da04b1b5c4a9bdcf36dc728065fa5
2f19ac6fc5d0d1a699a70faf07a2aa26a139e3a88aad34f5ef5c0840a7ce28f5

GOOOOD:
~/geth/geth --dev --datadir ~/bridgetest --syncmode "full" --http --http.addr "127.0.0.1" --http.port 8645 --ws --ws.addr "127.0.0.1" --ws.port 8646 --http.api web3,eth,debug,personal,net --ws.api web3,eth,debug,personal,net --vmdebug --gcmode "archive" --http.corsdomain "*" --http.vhosts "*" --ws.origins "*" --networkid 1337 --allow-insecure-unlock



node relay.js --source=wss://ropsten.infura.io/ws/v3/2cd3efbd02a24a3ea799ea5be970446d --target=ws://127.0.0.1:8546 --startBlock 9172100 --targetContract=0x10a9B3515C1679Ce40974F2dBF2b8F40638b8D8C --privateKey=2f19ac6fc5d0d1a699a70faf07a2aa26a139e3a88aad34f5ef5c0840a7ce28f5

GETH:
node relay.js --source=wss://ropsten.infura.io/ws/v3/2cd3efbd02a24a3ea799ea5be970446d --target=ws://127.0.0.1:8646 --startBlock 9175336 --privateKey=2f19ac6fc5d0d1a699a70faf07a2aa26a139e3a88aad34f5ef5c0840a7ce28f5 --targetContract=0x0bC08EAbEfa6d2c3F1A06Fcdf5408339D8b095b5

GANACHE:
node relay.js --source=wss://ropsten.infura.io/ws/v3/2cd3efbd02a24a3ea799ea5be970446d --target=http://127.0.0.1:8545 --startBlock 9175336 --privateKey=a01da66521b9f792af441b92a1e9c2a144ceea9ede66a60b9f92dea198efd054 --targetContract=0x95f5166C663b3680A3861f2Cdd548727Eb6e4B94


harhat:
node relay.js --source=wss://ropsten.infura.io/ws/v3/2cd3efbd02a24a3ea799ea5be970446d --target=ws://127.0.0.1:8545 --startBlock 9175660 --privateKey=0xc526ee95bf44d8fc405a158bb884d9d1238d99f0612e9f33d006bb0789009aaa --targetContract=0x3Bf9d3C0D5BAb03e286947041fb035e9936BD960


geth:
2f19ac6fc5d0d1a699a70faf07a2aa26a139e3a88aad34f5ef5c0840a7ce28f5

ganache:
71a57a955a600f2add77feeb4d5719c08ebf4acc2f95a13fde42641c14d4d549


- gas costs






--http.corsdomain "*"
--http.vhosts "*"
--ws.origins "*"
--rpc --rpccorsdomain "*"

geth --datadir test-chain-dir --rpc --dev --rpccorsdomain "https://remix.ethereum.org,http://remix.ethereum.org"




geth attach /Users/loredana/bridgetest/geth.ipc



--signer=<CLEF_LOCATION>/clef.ipc
```

// 0x40dC0eDDc80c382036b233C85C502Eeba6ceEC0C
// 0x24e2b2597bca1037b93da2c77d49153c54f29862



## Send ETH

Script sendEthAndVerify(address)
- sends ETH on source chain
- waits for confirmation on source chain & block to be added to target chain - 5 s
- constructs proof (either transaction proof or balance proof)
- sends proof to Prover on target chain - print data sent, so it can be replicated in Remix
- shows result true/false


- verify block hash exists in client
- verify transaction was included in block
- decode transaction data and check value is what is expected
- verify receipt was included in block
- decode receipt status and check it is true


2 instances of metamask & Remix
call script that sends ether
check account balance on chain A
check proof on prover B

factotum



- send eth to contract -> trigger



- actor1 addblocks
- actors2 challenge with proof

- prover looks ar certain block & sees that its not single -> tell you that you need to pay money, so it can tell you the results of the proof
1) run pure way
2) encourage proof to be true by putting money against it

- other people will put other blocks & his fork will not be the longest
- put his money on that block

- continous voting - by sending proofs that it is correct




This can be calculated
from the previous block’s difficulty level and the
timestamp; formally Hd



41)
D(H) ≡
(
D0 if Hi = 0
max D0, P(H)Hd + x × ς2 + 

parent.timestamp + x * difficulty_parameter + exponential_difficulty_symbol

x = parent.timestamp / 2048

finalize
50 block period to propose next batch

- send 10 blocks -> register
- if other blocks come, compare with the above
- if difficulty is bigger -> replace the old one
- if 50 blocks passed, register the blocks as valid.


proposal -> accepted hashes - move a couple of them to storage (ticker dumb bots) -> 2 types of way to earn points

- relayer - watches for FinalBlockChanged -> starts gathering blocks until some x block
- ticker - can be sent on each block
- updater - watches for BlockAdded & counts blocks until registerPeriod

- send





challenge block -> compute difficulty -> if better, we can revert the state.
- generalize 5 chains
chainid =>


- have an API for the contract & js scripts



- header data - for roots
- verify header - checks hash & client
- verify receipt -> checks receipt part of header
- verify logs -> checks log is part of receipt

verifyReceiptAndLog
verifyLog


forwardAndVerify - proxy


verifyTransaction - verifyProof, check header contains same root as proof

verifyHeaderAndTransaction



- address from signature and transaction
- event-based proxy
- verify transaction was successful - sender from ecverify
- verifyStorage

- verifyCode (remove)
- verifyBalance (remove)



0x0b552efab951231da6438aa6eb4db64189351bc4a8a1b1b8a79531662412fe56
0x8ba01195cd9f23bbf0b3c410ddf0765631e913f59661e79581d15957f8a60094



https://eips.ethereum.org/EIPS/eip-155


- diagram


0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000

# Cosmos-EVM Ideas and Prototypes

Other efforts: https://github.com/loredanacirstea/CV/tree/master/evmos


## Ethereum Precompile Proposals - Introspection EIP

- https://youtu.be/cR4tUl0Kzq8
- https://github.com/loredanacirstea/go-ethereum/tree/precompiles-core

We are exploring our Introspection Precompile proposal, which will give developers access to block, transaction, receipt, and log data from inside the EVM.


## Ethereum Precompile Proposals - IPFS (InterPlanetary FileSystem) EIP

- https://youtu.be/Yaf3uLNWDwg
- https://github.com/loredanacirstea/go-ethereum/tree/precompile-ipfs2

Today, we are showing a demo of our IPFS precompile proposal, that will allow developers to save and retrieve content to and from IPFS. 
Any chain that has a virtual machine will need an extension that allows it to create proofs and interact with decentralized storage systems that can hold a bigger data load than the chain.


## Ethereum Precompiles Proposals - On chain Proof Creation EIP

- https://youtu.be/VVNXztcXXFo
- https://github.com/loredanacirstea/go-ethereum/tree/precompiles-merkle-proofs

Today, we are showing a demo of our Proof Creation precompile proposal, that will allow developers to create Merkle proofs about the state of the chain. Proofs that a transaction or transaction receipt is included in a block, that a log has been emitted by a transaction, proof that an account had a certain balance or code or storage slot, at a given block.


## The EVM wars & the Cosmic Ethereum VM

- https://youtu.be/EzpPwVgjs4E

We need an Ethereum Virtual Machine playground, where more community members can test and try out their EVM proposals.
And this is where Evmos comes in.


## Ethereum Precompiles Proposals - IPLD (InterPlanetary Linked Data) EIP

- https://youtu.be/8M8Q5iO1cZ8
- https://github.com/loredanacirstea/go-ethereum/tree/precompiles-ipld2

A precompile for IPLD - the InterPlanetary Linked Data ecosystem, that will allow developers to save and retrieve content to and from IPLD. 
IPLD is an ecosystem of formats and data structures for building applications that can be fully decentralized. The goal is to enable decentralized data structures that are universally addressable and linkable.


## Ethereum Precompiles Proposals - Inter-Blockchain Communication (IBC)

- https://youtu.be/xCyji0gHD4U
- https://github.com/loredanacirstea/ethermint/tree/precompiles-ibc, https://github.com/loredanacirstea/ethermint/tree/precompiles-ibc7
- https://github.com/loredanacirstea/evmos/tree/precompile-ibc2

A demo of an EVM precompile for IBC - the Inter-Blockchain Communication protocol used by Cosmos. With an IBC precompile, you can send cross-chain messages from inside the EVM without the need for additional bridges. You take advantage of the existing IBC system and security for relaying messages.


## Evmos Native Rollups

- https://github.com/pipeos-one/goldengate/blob/master/research/EVM_Rollups.md

An EVM-based chain with PoS could be a settlement chain for spawned rollup-like chains based on Evmos (without the consensus layer, e.g. with a sequencer-like system). Data verification & availability is done on IPFS/IPLD (which have the awesome feature that you can republish data under the same CID at any time).
If the IBC precompile works as intended, you can have trust-minimized rollups bridging with the Cosmos ecosystem.


## EVM interpreter precompile

- https://youtu.be/uzc1ijYhZE8
- https://github.com/loredanacirstea/go-ethereum/tree/precompiles-evm
- https://github.com/loredanacirstea/ethermint/tree/precompiles-evm

Just by having this EVM interpreter inside the EVM as a precompile, you can have native and efficient mechanisms for layer 2 solutions like rollups. You can open a new way of storing and executing smart contracts. You can add multiple types of EVM to be tested in production without affecting the actual base layer.


## EVM Interpreter Precompile used as a Trustworthy Compute Engine (with a spreadsheet engine)

- https://youtu.be/kHDxDiM5xvQ

This spreadsheet becomes the most detailed EVM IDE. With direct access to the execution context and statistics about the most important EVM operations.


## Generalized Replay Bridge with Ethereum VM, IBC (Cosmos) & Evmos

- https://youtu.be/ayFzY4btFX4

A Generalized Replay Bridge can replay smart contract transactions on one or more chains, keeping state (of any type), in sync across chains. And this can be done selectively, for the smart contract state that you are interested in. For example, for keeping token balances in balance across contracts.


## Gas Refill Precompile - Prepay Ethereum VM transactions

- https://youtu.be/S9HLBwG6Ifo
- https://github.com/loredanacirstea/go-ethereum/tree/precompiles-gascontract

With this, users and contracts can prepay for future transactions and it can be possible to earn native tokens from nothing, just for providing a cron service for other users. 

## Account Abstraction for EVM Chains with Fast Finality (demoed on Evmos)

- https://youtu.be/xiu2yfYzE68
- https://github.com/loredanacirstea/ethermint/tree/prototypes/interchain-accounts
- https://github.com/loredanacirstea/evmos/tree/interchain-accounts, https://github.com/loredanacirstea/evmos/tree/interchain-accounts2

Allowing smart contracts to send and pay for transactions opens up new subdomains and new markets. You can have cron jobs on the blockchain with fees paid by a contract. A user can set aside payment for future transactions that will be made on his behalf. You can have validators being controlled by a smart contract.


AbstractAccounts Diagram https://github.com/pipeos-one/goldengate/blob/0dda0bd9a04de144b9ef3a0f988f6111846ea893/research/cosmos/AbstractAccounts.md

InterChainAccounts - registration diagram https://github.com/pipeos-one/goldengate/blob/0dda0bd9a04de144b9ef3a0f988f6111846ea893/research/cosmos/InterChainAccounts.md

## Trustless Bridging (1) with InterChain Transactions for EVM Smart Contracts, with Cosmos IBC & Evmos

- https://youtu.be/I7zYXEtMeD4
- https://github.com/loredanacirstea/ethermint/tree/prototypes/interchain-evm-transactions
- https://github.com/loredanacirstea/evmos/tree/interchain-evm-transactions

InterChain Transactions, interchain compatibility, and composability, interchain applications are the next major feature that any blockchain will need to have.
The following demo is done with tools from the Cosmos ecosystem, but if Ethereum 2 will implement the IBC precompile that I demoed in a previous video, then today's example could be possible also on Ethereum.
Today I am showing you a prototype of how you can use interchain accounts for EVM-powered Cosmos chains. This is the first time anyone designed and implemented such a demo.


Diagram: https://github.com/pipeos-one/goldengate/blob/0dda0bd9a04de144b9ef3a0f988f6111846ea893/research/cosmos/ICABridgingForEVMChains.md

## Cron Transactions Precompile for the EVM - cronjobs for the blockchain (demoed on Ethermint)

- https://youtu.be/1whMSUM0JyQ
- https://github.com/loredanacirstea/ethermint/tree/prototypes/cronjobs
- https://github.com/loredanacirstea/evmos/tree/prototypes/cronjobs

Send EVM transactions automatically, through a cronjob.

## Eventual Transactions - Expanding the Blockchain Limits

- https://youtu.be/nKIiETyH2K4
- https://github.com/loredanacirstea/ethermint/tree/prototypes/eventual_transactions

Send EVM transactions automatically, by emitting a smart contract event.

## Evmos's Fees Module

### Evmos's Fees Module Presentation

- https://youtu.be/N2wHCkXNqFA
- https://github.com/evmos/evmos/pull/436, https://github.com/evmos/evmos/pull/461, https://github.com/evmos/evmos/pull/464, https://github.com/evmos/evmos/pull/469, https://github.com/evmos/evmos/pull/471, https://github.com/evmos/evmos/pull/481, https://github.com/evmos/evmos/pull/586, https://github.com/evmos/evmos/pull/612

This is a presentation of Evmos's fees module, with technical details about design choices. 
I implemented version 1 of the fees module, as a volunteer effort for Evmos. And this summary is a volunteer effort for the Evmos community.

### Developer Gas Rewards @Layer 1 (a better EIP-1559) EIP Proposal:

- https://youtu.be/MJ64V1Dqm6M

Ethereum has introduced EIP 1559, where the dynamic block base fee, multiplied by the transaction's used gas is burned. So, instead of being burned entirely, you can send some of that gas to the contract deployer, like Evmos proposes.

### Let's talk about fees (didactic analysis) - for Ethereum or any EVM-based chains

- https://youtu.be/XMlNtI-5ZPQ

Developer funding can be done at the protocol level with the advantage of having less friction and no additional fees incurred by users.
You have now seen a didactic analysis of how it can be done, for Ethereum or any EVM-based chain.

## dTypeDB: The Inter Chain Database Demo Setup

- https://youtu.be/a9RI6xNzGpI
Setup for upcoming Inter-Chain Demos: Mythos, Logos and Ethos.

## The Mythos Kernel

- https://youtu.be/GGzL2JBtD64

Mythos is an inter-chain entity. The kernel is its native chain. It is derived from Ethermint/Evmos. Cosmos and EVM compatible. Governed by 3 principles: Kosher Currency, Firm Identity, Reliable Reputation.

## The Singularity - The First Inter-Chain DAO

- https://youtu.be/jsiDviYMvMc
The Singularity is an Inter-Chain Governing body over Inter-Chain Standards. 

## Evolve Evmos: Volunteer's Validator

- https://youtu.be/57oU_nl-96M

Give volunteers a powerful voice by increasing their voting power

## The Inter-Chain EVM Contracts. dTypeDB: The Inter-Chain Database – Demo 1

- https://youtu.be/g8gddxPnCr8

## The Inter-Chain ERC20 Token [dTypeDB: The Inter Chain Database – Demo 2] [Cosmos, Ethereum]

- https://youtu.be/fXg3i_1tPiU

The First Inter-Chain ERC20: a semantic singleton, uniquely referenced, with a synced totalSupply on all participating chains.

## The Inter-Chain NFTs(ERC721) [dTypeDB: The Inter Chain Database – Demo 3] [Cosmos, Ethereum]

- https://youtu.be/YB6ViFtHjmI

The First Inter-Chain NFT: a semantic singleton, uniquely referenced, with a synced NFT counter on all participating chains.

## The Virtuous Bribe: Decentralization and Chain Security in Blockchain Proof of Stake

- https://youtu.be/R4clQ47s7w4

Virtuously bribing stakers to maintain decentralization and chain security in PoS systems.
What are we protecting, why does it matter and what can we do.

## The nBridge - A Golden Gate Bridge Application

- https://youtu.be/12FU9iG1D08

Any chain can initiate multi-chain transactions on any or all of the chains in the ring.

## Quasar - Control your Cosmos, Evmos

- https://youtu.be/PlbAWUK54PU

With the Cosmos Quasar, we created a bidirectional axis of communication between execution engines on the same blockchain.

## ganas: A Wallet for the Inter-Chain [Part 1: IDE]

- https://youtu.be/S8CkNORE6V0

Ganas is the most extensible wallet. Made for the citizens of the new decentralized world order.

## Loredana @HackAtom Seoul 2022: Trailblazing the EVM Inter-Chain (supported by the Evmos Community)

- https://youtu.be/j5CVliOb-Ck

Workshop: [EVM: Trailblazing the Inter-Chain] with Loredana | evmos4volunteers

## The Inter-Chain Singular Object [hacker submission for Evmos @HackAtom, Seoul 2022]

- https://youtu.be/Khqv-1TbsMo
- https://github.com/loredanacirstea/identity
- See https://youtu.be/j5CVliOb-Ck (Trailblazing the Inter-Chain) first!

Won 3rd prize for Evmos: https://youtu.be/QA_k6tUNxCk?t=26726


## ganas: A Wallet for the Inter-Chain [Part 2: Caching and Sharing Data]

- https://youtu.be/QF9lNykzudQ

UI decluttering by managing your wallet features from a browsable tree of features. Cache for IPFS-based apps. File sharing. Object sharing

## ganas: A Wallet for the Inter-Chain [Part 3: WalletConnect Extensions]

- https://youtu.be/UAn4D62drUE

Ganas is compatible with WalletConnect 2.0 which enables the handover of transaction signing or sending requests from all other devices to the phone.

## ganas: A Wallet for the Inter Chain [Reveal 4: OSes and Devices]

- https://youtu.be/2ivLS95_u7Y

Ganas Mobile: iOS, Android ; phone, tablet
Ganas Desktop: MacOS
Ganas Web: Chrome
GanasX (browser extension): Chrome, Safari (desktop/laptop & mobile)


## The Blockchain Constitution - an Evmos Governance Proposal

- https://youtu.be/7gsuWWvCse4
- Navigate to each proposal right from this graph (click on the node name): https://github.com/the-laurel/chain-proposals/blob/main/evmos/PrecedenceGraph.md. 

Let's evolve together the basic building block of civilization: the Constitution.

## ganas: A Wallet for the Multi Chain [Reveal 5: Chat]

- https://youtu.be/dqxXEGGd7nw

## The BlockTree - Concept Definition [a.k.a. Semantic BlockChain]

- https://youtu.be/TA9kvgpMgjU

A block tree is formed by adding interdependencies between the blocks of several chains. It acts both as a semantic search for data and a rollup for blockchain data.

## Causally Derived, Interlinked Constitutional Framework - Application to Tgrade Blockchain

- https://youtu.be/jFEocwaEYj0
- https://github.com/the-laurel/chain-proposals/blob/main/tgrade/TechnicalLimitations.md
- Precedence Graph for Tgrade: https://github.com/the-laurel/chain-proposals/blob/main/tgrade/PrecedenceGraph.md

Let's evolve together the basic building block of civilization: the Constitution.

## ganas: A Wallet for the Multi Chain [Reveal 6: The BlockTree (Time)]

- https://youtu.be/4weKOMurQHA

A demo of a BlockTree, used in the context of implementing a chat as a blockchain with temporal index and search.

## ganas: A Wallet for the Multi Chain [Reveal 7: Cosmos Transactions]

- https://youtu.be/RSJ06qsQLog


## Ganas: A Wallet For Tgrade - Standard Cosmos Modules Transactions

- https://youtu.be/pWNOIVGPS_Y


## ganas: A Wallet for the Inter-Chain. Testing Releases.

- https://youtu.be/RusWApXp8q4

## ganas: A Wallet for the Inter-Chain. Reveal No.8: The Web Version

- https://youtu.be/LOOwh3pISRw

## ganas: A Wallet for the Inter-Chain. Write, compile, deploy EVM contracts and dApps.

- https://youtu.be/Nv3YrahLHHE

## ganas: A Wallet for the Inter-Chain. Governance: Submitting Proposals

- https://youtu.be/lEx0IAtLjoE

## ganas: A Wallet for the Inter-Chain. The Concert: ganas Web - ganasX - ganas Mobile

- https://youtu.be/C1xzweKfPuw

## ganas: A Wallet for the Inter-Chain. Identity Sync. Part 1: Add a custom chain (web & mobile)

- https://youtu.be/PcGgb7S-ZMg

## Quasar: Execute Cosmos Transactions from the EVM (with ganas)

- https://youtu.be/mMbZCM1TxKs

In the EVM, Quasar implements a Cosmos SDK precompile, that enables you to use Cosmos APIs from the EVM. The above demoes Cosmos transactions sent directly to the Cosmos SDK precompile, through the EVM.
We are proposing Quasar as a standard protocol for all blockchains with more than 1 execution engines. The formalization will be done by the Inter-Chain Pact office, supported in part by the Evmos Community by prop #45.

## Quasar: Execute Cosmos Queries from the EVM (with ganas) [built on Ethermint/Evmos]

- https://youtu.be/bo-L8gMdJJo

In the EVM, Quasar implements a Cosmos SDK precompile, that enables you to use Cosmos APIs from the EVM. The above demoes Cosmos queries, through the EVM.

## The EVM Interpreter Precompile

- https://youtu.be/WX-i5qyJpMk

Just by having this EVM interpreter inside the EVM as a precompiled native contract, you can have native and efficient mechanisms for layer 2 solutions like rollups. You can open a new way of storing and executing smart contracts. You can add multiple types of EVM to be tested in production without affecting the actual base layer.

This can be made possible, by opening up the EVM precompiles to have the same rights and information context as normal smart contracts: https://github.com/ethereum/go-ethereum/pull/26119

The EVM, through the Ethereum Yellow Paper, enforces bytecode analysis of valid jump destinations prior to executing the computation: https://github.com/ethereum/yellowpaper/issues/840

## Quasar: Execute Cosmos Transactions from an EVM Contract (e.g. multisig)

- https://youtu.be/k8oImUjMpHk

In the EVM, Quasar implements a Cosmos SDK precompile, that enables you to use Cosmos APIs from the EVM. The above demoes Cosmos transactions, done by any EVM smart contract.
This can be made possible, by opening up the EVM precompiles to have the same rights and information context as normal smart contracts: https://github.com/ethereum/go-ethereum/pull/26119



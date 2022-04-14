# The Web2 Shadow App

This is an extended and extensible infrastructure on web2 that should help and complement web3. Limited examples of this: Block Explorers (https://etherscan.io/), ChainLens App (https://www.youtube.com/watch?v=hem3ix-92yw&list=PL323JufuD9JCV67-vSQdb1uvLudyv8sXz&ab_channel=LoredanaCirstea).

This integrative app was long ago proposed to Ethereum in the form of ChainLens and its extensions, but was not adopted. Instead Ethereum integration with Web2 and IPFS is fragmented among Block Explorers, Sourcefy, Remix IDE, EthPM, and other smaller apps further fragmented in their own GitHub repos and disconnected IPFS sites.

## Uses
- searching/finding a dApp or smart contract by:
  - name
  - terms (tags)
  - text in the description (full text search)
  - input/output data types
- dApp and Contract development:
  - source code
  - database of libraries, interfaces, standards
  - ABI
  - IDE
  - IPFS pointers
  - wallet plugins
  - orchestrated deployment on multiple chains

## State Stored

Storing the state of key decentralized applications enables:
- fast redeploy on another chain of the same type
- fast discovery by users
- encourages new interoperability protocols by making interface data public (see the usecase of Pipeline (https://www.youtube.com/watch?v=TsXgE_AQgQU&list=PL323JufuD9JCV67-vSQdb1uvLudyv8sXz&index=7&ab_channel=LoredanaCirstea) )

- shadowed state (block explorer):
  - blocks
  - txs
  - contracts
  - account state
  - events
- hydration:
  - ABIs
  - contract sources
  - pointers to dApps, menus of dApps for each contract
  - tags, terms, classification
  - database of libraries, interfaces, standards: deployed contract classified accordingly
  - intra-chain contract links (if a contact has interactions with another)
  - inter-chain links (if a contract is deployed on other chains or has interactions with other contracts there)
  - bridging info
  - rollups data

## Stake and Earnings

The App should be hosted on a decentralized database (eventually with raft consensus) and IPFS solution. The service providers should be paid by the chain usage (for example by functioning as validators or contract developers at the same time).

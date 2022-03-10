# Golden Gate Bridging by Replay

## Light Client

If the chain does not benefit from IBC, it needs a light client of each of the bridged chains.

## IBC

For EVM, an IBC precompile can play the role of a light client. Build order (on each chain):

- Singleton Factory
- Singleton Proxy with IBC semaphores
- Singleton ACL
- other singleton contracts (to be remotely played)

## Singleton Contracts

The transaction reply pattern can be implemented on EVM<->EVM bridge by using the same address of contracts and nonce synch across pairs of chains.
Such enforcing has to follow:

- controlled creation of contracts (eventually synchoronized creation)
- controlled nonce and order of synchronized transactions

## ACL Contracts

- for ensuring required balance / eventual slashing

## Proxy Contracts

- redirect transactions to the contracts where they need to execute
- maintain nonce sync

## ERC20, EIP721, Asset minting contracts

These contracts are not compatible directly with replay bridging, but they can become compatible by adapter contracts (that forward transactions).
Also replay-compatible protocols that correspond to these standards should be standardized (for gas saving).

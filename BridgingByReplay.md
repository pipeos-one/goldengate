# Golden Gate Bridging by Replay

## Light Client

If the chain does not benefit from IBC, it needs a light client of each of the bridged chains.

## IBC

For EVM, an IBC precompile can play the role of a light client.

## Singleton Contracts

The transaction reply pattern can be implemented on EVM<->EVM bridge by using the same address of contracts and nonce synch across pairs of chains.
Such enforcing has to follow:

- controlled creation of contracts (eventually synchoronized creation)
- controlled nonce and order of synchronized transactions

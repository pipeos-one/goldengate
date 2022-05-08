# IC Smart Contracts

The Inter-Chain Smart Contracts are of 2 types: relayable (that hold the state in their respective chains) and mirrorable (that hold the same state on each chain). The mirrorable are also replayable, but not all replayable are mirrorable.

## EVM Specs

### Replayable

1. all API functions have an additional input: ChainID, that is required
2. there exists a function: ChainID() that returns the ID of the chain where the contract exists
3. all mutable functions forward to a locally-mutable function only if the ChainID input == this.ChainID(). Otherwise return.
4. mutable functions can be called only from the Inter-Chain Bridge address.

### Mirrorable

1. 1 and 2 from the Replayable requirements
2. all state needs to store also the chain localization (by chain ID) for that particular state
3. 3 from Replayable, but state is stored also in the case ChainID input != this.ChainID()
4. same as 4 from the above


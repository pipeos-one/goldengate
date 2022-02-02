# dTypeDB and Chain Bridging

This describes especially the EVM<->EVM bridging, but the same techniques may be applied to other chain computation engines.

## Other bridging solutions

From the point of view of the content that gets bridged, the bridges fall into 2 categories: data/state bridges and behavior bridges. The generalized behavior bridges are using a mechanism of transaction replay (if contracts can be deployed by the bridge mechanism to obtain the same address on both ends) or by correlated action (less generalizable).

We have implemented transaction replay and correlated actions in [The Golden Gate Bridge](https://github.com/loredanacirstea/goldengate).
The main problem with behavior bridging is the gas waste: it consumes the same amount of computation on the follower chain as in the change-leading chain. This can be optimized by bridging only the data or state. That way we could achieve the gas savings in 2 ways: by not computing anything else but the state change and by rolling-up consecutive state changes.

## Bridging by selective data/state mirroring

This is done by having efficient mechanisms to:

1. Concentrate the data/state into fewer contracts
2. Form data entities (or decentralized objects) that need to be locked as wholes
3. Select the entities of interest for mirroring
4. Change and lock the entities, if needed
5. Mirror entities changes in bulk
6. Unlock the synced entities
7. Verify correctness (if the mechanism is trustless)
8. Incentivize cooperation

For such purposes, we planned and implemented a typed database on-chain: dTypeDB.
dTypeDB presently solves points (1-6) with 7 and 8 in the process of being built.
For points 4, 5, 6 any on-chain solution needs an off-chain relayer component. This role may be played by IBC or Gravity Bridge.

### Lock/Unlock Selectively

Since points 1, 2, 3, 5 are trivial in the case of a database, we will explain points 4 and 6. The short explanation: by using bloom filters.

Consider 2 blockchains: B1 and B2. Each has a dTypeDB contract: C1 and C2. In each dTypeDB, there is a set S (same in type, structure, name) that is marked for mirroring. We will call the sets S1 and S2 the instantiations of S in C1 and C2 respectively.

Set S has N elements that have L slots in length and their key (index) has K bytes in length.
Suppose elements with key x1, x2, ..., xi get changed on B1: a bloom filter will be created on C1 (using the keys) and transmitted to C2: the elements that verify the filter will not be available for reading or writing on C2 until the sync happens. If the changes are small: the mirroring may happen without any pre-locking.

### Change Witness

For a series of slots changes: consider the slots' new values: n1..ni, a witness slot w, and a reversible and commutative operation o. We probably could safely use addition as o and substraction as reverse(o).

1. in contract C1: we start with value(w) = 0
2. we compute value(w) = o(value(w), n1..i) for each change
3. we send the final value of w to C2
4. the data on C2 becomes locked
5. in contract C2: we compute value(w) = reverse(o)(value(w), n1..i)
6. we check that value(w) = 0 that is part of the proof that all changes were processed

### Change Nonce

For changes in C1 selected state: consider the number of slot changes.

1. in contract C1: we start with a number (new values) Nv = 0
2. we compute Nv = Nv + 1 for each change
3. we send the final value of Nv to C2
4. the data on C2 becomes locked
5. in contract C2: we compute Nv = Nv - 1 for each change
6. we check that Nv = 0: that is part of the proof that all changes were processed

### IBC

Using IBC a data mirroring solution may lock the pertinent values on C2 before completing the transaction (atomic changes) on C1, by the mechanisms described above.
IBC's interface in an EVM chain may take the form of a precompile and be treated like any other contract.

At the end of processing the sync transaction/s on C2, C2 will use IBC to announce C1 of the completed mirroring (if both the change witness and the nonce tests pass), thus unlocking all newly-changed data entities on both C1 and C2.

## Conclusion

Given that dTypeDB is developed as a gas-optimized solution for the EVM (and less-optimized for Wasm), we expect that this type of EVM<->EVM (or even EVM<->Wasm, Wasm<->Wasm) bridge will also be the gas-optimized solution for data mirroring in general.

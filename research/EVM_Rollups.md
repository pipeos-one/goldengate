# EVM Rollups

```

[Evmos Chain] -> Introspection [Evmos Chain]
[<package> Evmos Chain|
	[Precompiles |
    	i: Introspection ||
        b: IBC ||
        s: Chain Spawn |
        spawnWithContracts(contracts: address\[\])
        ||
        d: IPLD|
        saveProof(cbor_proof: bytes\[\])
        loadProofPart(CID: bytes\[\], cbor_path: bytes\[\]) ||
        o: EVM Interpreter|
        (optional - for gas savings)
    ] -> [Contracts |
    	[Rollups/Spawns Manager |
        	StateRoots: bytes32\[\]
            |
            verify()
            evmInterpret()
            spawnEvmos()
        ]
        [Other Contracts |
        	(to be spawned by the Chain Spawn) ||
            ERC20 type
            DEX type
            ERC721 type
            ...
        ]
    ]
    [Contracts] -> [Precompiles]
] <-> [IPLD]

[Evmos Chain] <-> IBC [<abstract> Rollup Bundle]
[Evmos Chain] <-> IBC [Another Cosmos Chain]


[Rollup Bundle] <-> IBC [Another Evmos Chain 1]
[Rollup Bundle] <-> IBC [Another Evmos Chain 2]
[Rollup Bundle] <-> IBC [Another Evmos Chain 3]


```

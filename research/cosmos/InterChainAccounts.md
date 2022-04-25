# Cosmos InterChain Accounts

Spec: https://github.com/cosmos/ibc/blob/52a9094a5bc8c5275e25c19d0b2d9e6fd80ba31c/spec/app/ics-027-interchain-accounts/README.md#identifer-formats

## ICA Registration Mechanism

```mermaid
sequenceDiagram
    autonumber
    participant ChainA
    participant Relayer
    participant ChainB
    ChainA->>+ChainA: RegisterICA
    Note left of ChainA: MsgServer:
    ChainA->>+ChainA: ChanOpenInit
    Note over ChainA,Relayer: ChanOpenInit event
    Note over ChainB: MsgServer:
    Relayer->>+ChainB: ChanOpenTry
    Note right of ChainB: onChanOpenTry:<br> store ICA => owner
    Note over ChainB,Relayer: ChanOpenTry event
    Relayer->>+ChainA: ChanOpenAck
    Note left of ChainA: onChanOpenAck:<br> store portID => ICA <br> activate channel
    Note over ChainA,Relayer: ChanOpenAck event
    Relayer->>+ChainB: ChanOpenConfirm
    Note right of ChainB: onChanOpenConfirm:<br> activate channel
```


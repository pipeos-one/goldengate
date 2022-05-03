# Generalized State Bridge Between Cosmos-EVM Chains

This is an original idea for bridging Cosmos Chains with EVM enabled. Based on Cosmos [InterChain Accounts](./cosmos/InterChainAccounts.md) and our own flavour of (original idea) [Abstract Accounts](./cosmos/AbstractAccounts.md) (abstract programmatic accounts).


```mermaid
sequenceDiagram
    autonumber
    participant EOA_or_Contract
    participant IcaPrecompile_chain1
    participant InterTxModule_chain1
    participant IcaModule_chain1
    participant IcaModule_chain2
    participant InterTxModule_chain2
    participant EvmModule_chain2

    EOA_or_Contract->>+IcaPrecompile_chain1: emitTx
    Note over EOA_or_Contract,IcaPrecompile_chain1: emitTx(connID, to, value,<br> gasLimit, calld, signature)
    IcaPrecompile_chain1->>+InterTxModule_chain1: SubmitEthereumTx
    InterTxModule_chain1->>+InterTxModule_chain1: sign EthereumTx with Abstract Account
    Note over InterTxModule_chain1,IcaModule_chain1: MsgWrappedEthereumTx<br>From: ICA_Address
    InterTxModule_chain1->>+IcaModule_chain1: SubmitTx
    Note over IcaModule_chain1,IcaModule_chain2: IBC relay packets
    IcaModule_chain2->>+InterTxModule_chain2: UnwrapEthereumTx
    InterTxModule_chain2->>+InterTxModule_chain2: deduct fees from ICA
    InterTxModule_chain2->>+EvmModule_chain2: EthereumTx
    EvmModule_chain2->>+EvmModule_chain2: TargetContract execution
    EvmModule_chain2->>+InterTxModule_chain2: EthereumTxReceipt
    InterTxModule_chain2->>+IcaModule_chain2: EthereumTxReceipt
    Note over IcaModule_chain1,IcaModule_chain2: IBC relay packets
    IcaModule_chain1->>+InterTxModule_chain1: EthereumTxReceipt
    InterTxModule_chain1->>+IcaPrecompile_chain1: EthereumTxReceipt
    IcaPrecompile_chain1->>+EOA_or_Contract: EthereumTxReceipt

```

# Abstract Accounts

References:

- https://eips.ethereum.org/EIPS/eip-4337
- https://eips.ethereum.org/EIPS/eip-2938
- https://github.com/ethereum/EIPs/issues/86


```mermaid
sequenceDiagram
    autonumber
    participant User
    participant Contract1
    participant AbstractAccountPrecompile
    participant AbstractAccountsModule
    %% participant Contract1AbstractAccount
    participant Contract2
    Note over User: Trigger can be<br>external (e.g. user)<br>or internal (cron job)
    User->>+Contract1: trigger tx
    Contract1->>+AbstractAccountPrecompile: sendTx (to,value,gasLimit,data)
    AbstractAccountPrecompile->>+AbstractAccountsModule: sendTx
    Note over AbstractAccountsModule: get Contract1 abstract account (AAC1)
    AbstractAccountsModule->>+AbstractAccountsModule: AAC1 sign tx
    Note over AbstractAccountsModule: evmModule.EthereumTx
    AbstractAccountsModule->>+Contract2: tx
    Contract2->>+AbstractAccountsModule: receipt2
    AbstractAccountsModule->>+AbstractAccountPrecompile: receipt2
    AbstractAccountPrecompile->>+Contract1: receipt2
    Contract1->>User: receipt1

```


## Usecases

### Cron Transactions

```mermaid
sequenceDiagram
    autonumber
    participant EOA
    participant CronPrecompile
    participant CronModule
    participant EpochModule
    participant AbstractAccountModule
    participant EvmModule

    EOA->>+CronPrecompile: setCronTx(epochID, bytes msgEthereumTx)
    Note over EOA,CronPrecompile: cron
    CronPrecompile->>CronModule: RegisterCron
    CronModule->>CronModule: store cron
    CronModule->>CronPrecompile: cron identifier
    CronPrecompile->>EOA: receipt
    EpochModule--)CronModule: epoch event
    CronModule->>CronModule: run epoch crons
    loop run epoch crons
        Note over AbstractAccountModule: Cosmos or Ethereum tx
        CronModule->>AbstractAccountModule: ForwardEthereumTx(MsgEthereumTx)
    end

    AbstractAccountModule->>+EvmModule: apply EthereumTx(MsgEthereumTx)
    Note over EvmModule: TargetContract.increment()
    EvmModule->>AbstractAccountModule: EthereumTxReceipt
    AbstractAccountModule->>EpochModule: EthereumTxReceipt
    EpochModule->>CronModule: emit Cosmos event

```

### Eventual Transactions

```mermaid
sequenceDiagram
    autonumber
    participant EOA
    participant EvmModule
    participant EventfulContract
    participant AbstractAccountModule

    EOA->>+EvmModule: EventfulContract.Function
    EvmModule->>+EvmModule: execute tx
    EvmModule->>+EventfulContract: call Function
    Note over EventfulContract: emit SendTx(to, value, gasLimit, calldata)
    EventfulContract->>+EvmModule: result, logs
    EvmModule->>+AbstractAccountModule: PostTxProcessing hook (receipt)
    AbstractAccountModule->>+AbstractAccountModule: ForwardEthereumTx()
    AbstractAccountModule->>+node: BroadcastTxAsync()
    node->>+AbstractAccountModule: response, error
    Note over node: Tx is checked for validity
    node->>+node: CheckTx
    Note over node: Tx is included in a future block
    node->>+node: DeliverTx
    Note over node: Execute tx
    node->>+EvmModule: TargetContract.call<br>(value, gasLimit, calldata)
    EvmModule->>+TargetContract: call (value, gasLimit, calldata)
    TargetContract->>+EvmModule: result
    EvmModule->>+node: receipt

```

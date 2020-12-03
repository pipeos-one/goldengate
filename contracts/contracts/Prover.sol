pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./interface/iLightClient.sol";
import "./interface/iProver.sol";
import "./lib/ECVerify.sol";

contract Prover is iProver {
    using MPT for MPT.MerkleProof;

    iLightClient public client;

    constructor(address bridgeClient) {
        client = iLightClient(bridgeClient);
    }

    function lightClient() view public override returns (address _lightClient) {
        return address(client);
    }

    function verifyTrieProof(MPT.MerkleProof memory data) pure public override returns (bool) {
        return data.verifyTrieProof();
    }

    function verifyHeader(
        EthereumDecoder.BlockHeader memory header
    )
        view public override returns (bool valid, string memory reason)
    {
        bytes32 blockHash = keccak256(getBlockRlpData(header));
        if (blockHash != header.hash) return (false, "Header data or hash invalid");

        // Check block hash was registered in light client
        bytes32 blockHashClient = client.getConfirmedBlockHash(header.number);
        if (blockHashClient != header.hash) return (false, "Unregistered block hash");

        return (true, "");
    }

    function verifyTransaction(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory txdata
    )
        pure public override returns (bool valid, string memory reason)
    {
        if (header.transactionsRoot != txdata.expectedRoot) return (false, "verifyTransaction - different trie roots");

        valid = txdata.verifyTrieProof();
        if (!valid) return (false, "verifyTransaction - invalid proof");

        return (true, "");
    }

    function verifyReceipt(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory receiptdata
    )
        pure public override returns (bool valid, string memory reason)
    {
        if (header.receiptsRoot != receiptdata.expectedRoot) return (false, "verifyReceipt - different trie roots");

        valid = receiptdata.verifyTrieProof();
        if (!valid) return (false, "verifyReceipt - invalid proof");

        return (true, "");
    }

    function verifyAccount(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory accountdata
    )
        pure public override returns (bool valid, string memory reason)
    {
        if (header.stateRoot != accountdata.expectedRoot) return (false, "verifyAccount - different trie roots");

        valid = accountdata.verifyTrieProof();
        if (!valid) return (false, "verifyAccount - invalid proof");

        return (true, "");
    }

    function verifyLog(
        MPT.MerkleProof memory receiptdata,
        bytes memory logdata,
        uint256 logIndex
    )
        pure public override returns (bool valid, string memory reason)
    {
        EthereumDecoder.TransactionReceiptTrie memory receipt = EthereumDecoder.toReceipt(receiptdata.expectedValue);

        if (keccak256(logdata) == keccak256(EthereumDecoder.getLog(receipt.logs[logIndex]))) {
            return (true, "");
        }
        return (false, "Log not found");
    }

    function verifyTransactionAndStatus(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory receiptdata
    )
        pure external override returns (bool valid, string memory reason)
    {

    }

    function verifyCode(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory accountdata
    )
        pure public override returns (bool valid, string memory reason)
    {

    }

    function verifyStorage(
        MPT.MerkleProof memory accountProof,
        MPT.MerkleProof memory storageProof
    )
        pure public override returns (bool valid, string memory reason)
    {
        EthereumDecoder.Account memory account = EthereumDecoder.toAccount(accountProof.expectedValue);

        if (account.storageRoot != storageProof.expectedRoot) return (false, "verifyStorage - different trie roots");

        valid = storageProof.verifyTrieProof();
        if (!valid) return (false, "verifyStorage - invalid proof");

        return (true, "");
    }

    function getTransactionSender(
        MPT.MerkleProof memory txdata,
        uint256 chainId
    )
        pure public returns (address sender)
    {
        EthereumDecoder.Transaction memory transaction = EthereumDecoder.toTransaction(txdata.expectedValue);
        bytes memory txraw = EthereumDecoder.getTransactionRaw(transaction, chainId);

        bytes32 message_hash = keccak256(txraw);
        sender = ECVerify.ecverify(message_hash, transaction.v, transaction.r, transaction.s);
    }

    // Exposing encoder & decoder functions

    function getTransactionHash(bytes memory signedTransaction) public pure returns (bytes32 hash) {
        hash = keccak256(signedTransaction);
    }

    function getBlockHash(EthereumDecoder.BlockHeader memory header) public pure returns (bytes32 hash) {
        return keccak256(getBlockRlpData(header));
    }

    function getBlockRlpData(EthereumDecoder.BlockHeader memory header) public pure returns (bytes memory data) {
        return EthereumDecoder.getBlockRlpData(header);
    }

    function toBlockHeader(bytes memory data) public pure returns (EthereumDecoder.BlockHeader memory header) {
        return EthereumDecoder.toBlockHeader(data);
    }

    function getLog(EthereumDecoder.Log memory log) public pure returns (bytes memory data) {
        return EthereumDecoder.getLog(log);
    }

    function getReceiptRlpData(EthereumDecoder.TransactionReceiptTrie memory receipt) public pure returns (bytes memory data) {
        return EthereumDecoder.getReceiptRlpData(receipt);
    }

    function toReceiptLog(bytes memory data) public pure returns (EthereumDecoder.Log memory log) {
        return EthereumDecoder.toReceiptLog(data);
    }

    function toReceipt(bytes memory data) public pure returns (EthereumDecoder.TransactionReceiptTrie memory receipt) {
        return EthereumDecoder.toReceipt(data);
    }

    function toTransaction(bytes memory data) public pure returns (EthereumDecoder.Transaction memory transaction) {
        return EthereumDecoder.toTransaction(data);
    }

    function toAccount(bytes memory data) public pure returns (EthereumDecoder.Account memory account) {
        return EthereumDecoder.toAccount(data);
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/EthereumDecoder.sol";
import "../lib/MPT.sol";

interface iProver {
    function lightClient() view external returns (address _lightClient);

    function verifyTrieProof(MPT.MerkleProof memory data) pure external returns (bool);

    function verifyTransaction(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory txdata
    ) view external returns (bool);

    function verifyReceipt(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory receiptdata
    ) view external returns (bool);

    function verifyAccount(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory accountdata
    ) view external returns (bool);

    function verifyLog(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory receiptdata,
        bytes memory logdata,
        uint256 logIndex
    ) view external returns (bool);

    function verifyTransactionAndStatus(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory receiptdata
    ) view external returns (bool);

    function verifyCode(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory accountdata
    ) view external returns (bool);

    function verifyBalance(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory txdata,
        MPT.MerkleProof memory receiptdata,
        uint256 value
    ) view external returns (bool);

    function verifyStorage(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory accountProof,
        MPT.MerkleProof memory storageProof
    ) view external returns (bool);
}

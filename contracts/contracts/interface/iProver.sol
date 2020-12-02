pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/EthereumDecoder.sol";
import "../lib/MPT.sol";

interface iProver {
    function lightClient() view external returns (address _lightClient);

    function verifyTrieProof(MPT.MerkleProof memory data) pure external returns (bool);

    function verifyHeader(
        EthereumDecoder.BlockHeader memory header
    ) view external returns (bool valid, string memory reason);

    function verifyTransaction(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory txdata
    ) view external returns (bool valid, string memory reason);

    function verifyReceipt(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory receiptdata
    ) view external returns (bool valid, string memory reason);

    function verifyAccount(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory accountdata
    ) view external returns (bool valid, string memory reason);

    function verifyLog(
        MPT.MerkleProof memory receiptdata,
        bytes memory logdata,
        uint256 logIndex
    ) view external returns (bool valid, string memory reason);

    function verifyTransactionAndStatus(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory receiptdata
    ) view external returns (bool valid, string memory reason);

    function verifyCode(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory accountdata
    ) view external returns (bool valid, string memory reason);

    function verifyStorage(
        MPT.MerkleProof memory accountProof,
        MPT.MerkleProof memory storageProof
    ) view external returns (bool valid, string memory reason);
}

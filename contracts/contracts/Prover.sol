pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// import "./lib/EthereumDecoder.sol";
// import "./lib/MPT.sol";
import "./interface/iLightClient.sol";
import "./interface/iProver.sol";

contract Prover is iProver {
    using MPT for MPT.MerkleProof;

    iLightClient public client;

    mapping(address => uint256) accountNonces;

    constructor(address bridgeClient) {
        client = iLightClient(bridgeClient);
    }

    function getSignedTransaction(
        uint256 nonce,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 value,
        address to,
        bytes memory data,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (bytes memory signedTransaction) {

    }

    function getTransactionHash(bytes memory signedTransaction) public pure returns (bytes32 hash) {
        hash = keccak256(signedTransaction);
    }

    function getBlockRlpData(EthereumDecoder.BlockHeader memory header) public pure returns (bytes memory data) {
        data = EthereumDecoder.getBlockRlpData(header);
    }

    function getBlockHash(EthereumDecoder.BlockHeader memory header) public pure returns (bytes32 hash) {
        return keccak256(getBlockRlpData(header));
    }

    function getReceiptRlpData(EthereumDecoder.TransactionReceiptTrie memory receipt) public pure returns (bytes memory data) {
        data = EthereumDecoder.getReceiptRlpData(receipt);
    }

    function toBlockHeader(bytes memory rlpHeader) public pure returns (EthereumDecoder.BlockHeader memory header)
    {
        header = EthereumDecoder.toBlockHeader(rlpHeader);
    }

    function lightClient() view public override returns (address _lightClient) {
        return address(client);
    }

    function verifyTrieProof(MPT.MerkleProof memory data) pure public override returns (bool) {
        return data.verifyTrieProof();
    }

    function verifyTransaction(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory txdata
    )
        view public override returns (bool)
    {

    }

    function verifyReceipt(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory receiptdata
    )
        view public override returns (bool)
    {

    }

    function verifyAccount(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory accountdata
    )
        view public override returns (bool)
    {

    }

    function verifyLogs(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory receiptdata
    )
        view public override returns (bool)
    {

    }

    function verifyTransactionAndStatus(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory receiptdata
    )
        view public override returns (bool)
    {

    }

    function verifyCode(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory accountdata
    )
        view public override returns (bool)
    {

    }

    function verifyBalance(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory txdata,
        MPT.MerkleProof memory receiptdata,
        uint256 value
    ) view public override returns (bool)
    {
        EthereumDecoder.Transaction memory transaction = EthereumDecoder.toTransaction(txdata.expectedValue);
        EthereumDecoder.TransactionReceiptTrie memory receipt = EthereumDecoder.toReceipt(receiptdata.expectedValue);

        // Check block hash is hash(rlp(blockData))
        bytes32 blockHash = getBlockHash(header);
        require(blockHash == header.hash, "Header data or hash invalid");

        // Check block hash was registered in light client
        bytes32 blockHashClient = client.getConfirmedBlockHash(header.number);
        require(blockHashClient > 0, "Unregistered block hash");

        // decode receipt status and check it is true
        require(receipt.status == 1, "Transaction receipt status failed");

        // TODO: check sender sent transaction
        require(transaction.value == value, "Wrong transaction value");

        // TODO meld two verification - they share indexes and header data
        // TODO check storage proofs -> storageHash

        // Check proofs are valid
        require(txdata.verifyTrieProof());
        require(receiptdata.verifyTrieProof());
        return true;
    }

    function verifyStorage(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory accountProof,
        MPT.MerkleProof memory storageProof
    ) view public override returns (bool)
    {
        EthereumDecoder.Account memory account = EthereumDecoder.toAccount(accountProof.expectedValue);

        // Check block hash is hash(rlp(blockData))
        bytes32 blockHash = getBlockHash(header);
        // require(blockHash == header.hash, "Header data or hash invalid");

        // Check block hash was registered in light client
        bytes32 blockHashClient = client.getConfirmedBlockHash(header.number);
        require(blockHashClient > 0, "Unregistered block hash");

        // Check storage root is part of the account
        require(storageProof.expectedRoot == account.storageRoot, "Account storageRoot or storage proof invalid. ");

        // check account root
        // TODO meld two verification - they share indexes and header data

        // Check proofs are valid
        require(accountProof.verifyTrieProof());
        require(storageProof.verifyTrieProof());

        return true;
    }


    function forwardAndVerify(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory accountdata,
        MPT.MerkleProof memory txdata,
        MPT.MerkleProof memory receiptdata,
        address sender  // TODO computed from signed transaction data
    )
        public returns (bytes memory)
    {
        EthereumDecoder.Account memory account = EthereumDecoder.toAccount(accountdata.expectedValue);
        EthereumDecoder.Transaction memory transaction = EthereumDecoder.toTransaction(txdata.expectedValue);
        EthereumDecoder.TransactionReceiptTrie memory receipt = EthereumDecoder.toReceipt(receiptdata.expectedValue);

        // Check block hash is hash(rlp(blockData))
        bytes32 blockHash = getBlockHash(header);
        require(blockHash == header.hash, "Header data or hash invalid");

        // Check block hash was registered in light client
        bytes32 blockHashClient = client.getConfirmedBlockHash(header.number);
        require(blockHashClient > 0, "Unregistered block hash");

        // check tx & receipt have same key
        require(keccak256(txdata.key) == keccak256(receiptdata.key), "Transaction & receipt index must be the same.");

        // TODO Check receipt.from ecverified from signed transaction

        // Check proofs are valid
        require(accountdata.verifyTrieProof(), "Invalid account proof");
        require(txdata.verifyTrieProof(), "Invalid transaction proof");
        require(receiptdata.verifyTrieProof(), "Invalid receipt proof");

        // Account nonce must be kept in sync to ensure data is the same
        // First time use just records the nonce, so it is never replayed
        if (accountNonces[sender] > 0) {
            require(account.nonce == accountNonces[sender] + 1, "Sender nonce out of sync");
        }
        // Increase nonce regardless of the transaction status (success/fail)
        accountNonces[sender] = account.nonce;

        (bool success, bytes memory data) = transaction.to.call{value: transaction.value, gas: transaction.gasLimit}(transaction.data);
        uint8 _success = success ? uint8(1) : uint8(0);
        require(_success == receipt.status, "Diverged transaction status");

        return data;
    }
}

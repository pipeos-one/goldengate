pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./Prover.sol";

contract ProverStateSync is Prover {
    mapping(address => uint256) accountNonces;

    constructor(address bridgeClient) Prover(bridgeClient) {}

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

        (bool valid, string memory reason) = verifyHeader(header);
        if (!valid) revert(reason);

        // check tx & receipt have same key
        require(keccak256(txdata.key) == keccak256(receiptdata.key), "Transaction & receipt index must be the same.");

        // TODO Check receipt.from ecverified from signed transaction

        // Check proofs are valid
        (valid, reason) = verifyTransaction(header, txdata);
        if (!valid) revert(reason);

        (valid, reason) = verifyReceipt(header, receiptdata);
        if (!valid) revert(reason);

        (valid, reason) = verifyAccount(header, accountdata);
        if (!valid) revert(reason);

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

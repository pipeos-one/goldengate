pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./RLPEncode.sol";
import "./RLPDecode.sol";
import "./EthereumDecoder.sol";

interface EthereumClient {
    function getValidBlockHash(uint256 height) view external returns (bytes32 hash);
}

contract Prover {
    using RLPDecode for RLPDecode.RLPItem;
    using RLPDecode for RLPDecode.Iterator;

    struct MerkleProof {
        bytes32 expectedRoot;
        bytes key;
        bytes[] proof;
        uint256 keyIndex;
        uint256 proofIndex;
        bytes expectedValue;
    }

    EthereumClient public client;

    mapping(address => uint256) accountNonces;

    constructor(address bridgeClient) {
        client = EthereumClient(bridgeClient);
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

    function nthRlpItem(RLPDecode.Iterator memory it, uint256 idx) internal pure returns(RLPDecode.RLPItem memory item) {
        while(it.hasNext() && idx > 1) {
            it.next();
            idx --;
        }
        return it.next();
    }

    function rlp2List(bytes memory data) public pure returns (bytes[] memory decoded)
    {
        RLPDecode.RLPItem[] memory list = RLPDecode.toRlpItem(data).toList();
        bytes[] memory decoded = new bytes[](list.length);

        for (uint256 i = 0; i < list.length; i++) {
            decoded[i] = list[i].toBytes();
        }
        return decoded;
    }

    function encodeproof(bytes[] memory data) public pure returns (bytes memory encoded) {
        bytes[] memory list = new bytes[](data.length);

        for (uint256 i = 0; i < data.length; i ++) {
            list[i] = RLPEncode.encodeBytes(data[i]);
        }
        encoded = RLPEncode.encodeList(list);
    }

    function forwardAndVerify(
        EthereumDecoder.BlockHeader memory header,
        MerkleProof memory accountdata,
        MerkleProof memory txdata,
        MerkleProof memory receiptdata,
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
        bytes32 blockHashClient = client.getValidBlockHash(header.number);
        require(blockHashClient > 0, "Unregistered block hash");

        // check tx & receipt have same key
        require(keccak256(txdata.key) == keccak256(receiptdata.key), "Transaction & receipt index must be the same.");

        // TODO Check receipt.from ecverified from signed transaction

        // Check proofs are valid
        require(verifyTrieProof(accountdata), "Invalid account proof");
        require(verifyTrieProof(txdata), "Invalid transaction proof");
        require(verifyTrieProof(receiptdata), "Invalid receipt proof");

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

    function verifyStorage(
        EthereumDecoder.BlockHeader memory header,
        MerkleProof memory accountProof,
        MerkleProof memory storageProof
    ) view public returns (bool)
    {
        EthereumDecoder.Account memory account = EthereumDecoder.toAccount(accountProof.expectedValue);

        // Check block hash is hash(rlp(blockData))
        bytes32 blockHash = getBlockHash(header);
        // require(blockHash == header.hash, "Header data or hash invalid");

        // Check block hash was registered in light client
        bytes32 blockHashClient = client.getValidBlockHash(header.number);
        require(blockHashClient > 0, "Unregistered block hash");

        // Check storage root is part of the account
        require(storageProof.expectedRoot == account.storageRoot, "Account storageRoot or storage proof invalid. ");

        // check account root
        // TODO meld two verification - they share indexes and header data

        // Check proofs are valid
        require(verifyTrieProof(accountProof));
        require(verifyTrieProof(storageProof));

        return true;
    }

    function verifyBalance(
        EthereumDecoder.BlockHeader memory header,
        MerkleProof memory txdata,
        MerkleProof memory receiptdata,
        uint256 value
    ) view public returns (bool)
    {
        EthereumDecoder.Transaction memory transaction = EthereumDecoder.toTransaction(txdata.expectedValue);
        EthereumDecoder.TransactionReceiptTrie memory receipt = EthereumDecoder.toReceipt(receiptdata.expectedValue);

        // Check block hash is hash(rlp(blockData))
        bytes32 blockHash = getBlockHash(header);
        require(blockHash == header.hash, "Header data or hash invalid");

        // Check block hash was registered in light client
        bytes32 blockHashClient = client.getValidBlockHash(header.number);
        require(blockHashClient > 0, "Unregistered block hash");

        // decode receipt status and check it is true
        require(receipt.status == 1, "Transaction receipt status failed");

        // TODO: check sender sent transaction
        require(transaction.value == value, "Wrong transaction value");

        // TODO meld two verification - they share indexes and header data
        // TODO check storage proofs -> storageHash

        // Check proofs are valid
        require(verifyTrieProof(txdata));
        require(verifyTrieProof(receiptdata));
        return true;
    }

    function verifyTrieProof(
        MerkleProof memory data
    ) pure public returns (bool)
    {
        bytes memory node = data.proof[data.proofIndex];
        RLPDecode.Iterator memory dec = RLPDecode.toRlpItem(node).iterator();

        if (data.keyIndex == 0) {
            require(keccak256(node) == data.expectedRoot, "verifyTrieProof root node hash invalid");
        }
        else if (node.length < 32) {
            bytes32 root = bytes32(dec.next().toUint());
            require(root == data.expectedRoot, "verifyTrieProof < 32");
        }
        else {
            require(keccak256(node) == data.expectedRoot, "verifyTrieProof else");
        }

        uint256 numberItems = RLPDecode.numItems(dec.item);

        // branch
        if (numberItems == 17) {
            return verifyTrieProofBranch(data);
        }
        // leaf / extension
        else if (numberItems == 2) {
            return verifyTrieProofLeafOrExtension(dec, data);
        }

        if (data.expectedValue.length == 0) return true;
        else return false;
    }

    function verifyTrieProofBranch(
        MerkleProof memory data
    ) pure public returns (bool)
    {
        bytes memory node = data.proof[data.proofIndex];

        if (data.keyIndex >= data.key.length) {
            bytes memory item = RLPDecode.toRlpItem(node).toList()[16].toBytes();
            if (keccak256(item) == keccak256(data.expectedValue)) {
                return true;
            }
        }
        else {
            uint256 index = uint256(uint8(data.key[data.keyIndex]));
            bytes memory _newExpectedRoot = RLPDecode.toRlpItem(node).toList()[index].toBytes();

            if (!(_newExpectedRoot.length == 0)) {
                data.expectedRoot = b2b32(_newExpectedRoot);
                data.keyIndex += 1;
                data.proofIndex += 1;
                return verifyTrieProof(data);
            }
        }

        if (data.expectedValue.length == 0) return true;
        else return false;
    }

    function verifyTrieProofLeafOrExtension(
        RLPDecode.Iterator memory dec,
        MerkleProof memory data
    ) pure public returns (bool)
    {
        bytes memory nodekey = dec.next().toBytes();
        bytes memory nodevalue = dec.next().toBytes();
        uint256 prefix;
        assembly {
            let first := shr(248, mload(add(nodekey, 32)))
            prefix := shr(4, first)
        }

        if (prefix == 2) {
            uint256 length = nodekey.length - 1;
            bytes memory actualKey = sliceTransform(nodekey, 33, length, false);
            bytes memory restKey = sliceTransform(data.key, 32 + data.keyIndex, length, false);
            if (keccak256(data.expectedValue) == keccak256(nodevalue)) {
                if (keccak256(actualKey) == keccak256(restKey)) return true;
                if (keccak256(expandKeyEven(actualKey)) == keccak256(restKey)) return true;
            }
        }
        else if (prefix == 3) {
            bytes memory actualKey = sliceTransform(nodekey, 32, nodekey.length, true);
            bytes memory restKey = sliceTransform(data.key, 32 + data.keyIndex, data.key.length - data.keyIndex, false);
            if (keccak256(data.expectedValue) == keccak256(nodevalue)) {
                if (keccak256(actualKey) == keccak256(restKey)) return true;
                if (keccak256(expandKeyOdd(actualKey)) == keccak256(restKey)) return true;
            }
        }
        else if (prefix == 0) {
            uint256 extensionLength = nodekey.length - 1;
            bytes memory shared_nibbles = sliceTransform(nodekey, 33, extensionLength, false);
            bytes memory restKey = sliceTransform(data.key, 32 + data.keyIndex, extensionLength, false);
            if (
                keccak256(shared_nibbles) == keccak256(restKey) ||
                keccak256(expandKeyEven(shared_nibbles)) == keccak256(restKey)

            ) {
                data.expectedRoot = b2b32(nodevalue);
                data.keyIndex += extensionLength;
                data.proofIndex += 1;
                return verifyTrieProof(data);
            }
        }
        else if (prefix == 1) {
            uint256 extensionLength = nodekey.length;
            bytes memory shared_nibbles = sliceTransform(nodekey, 32, extensionLength, true);
            bytes memory restKey = sliceTransform(data.key, 32 + data.keyIndex, extensionLength, false);
            if (
                keccak256(shared_nibbles) == keccak256(restKey) ||
                keccak256(expandKeyEven(shared_nibbles)) == keccak256(restKey)
            ) {
                data.expectedRoot = b2b32(nodevalue);
                data.keyIndex += extensionLength;
                data.proofIndex += 1;
                return verifyTrieProof(data);
            }
        }
        else {
            revert("Invalid proof");
        }
        if (data.expectedValue.length == 0) return true;
        else return false;
    }

    function b2b32(bytes memory data) pure internal returns(bytes32 part) {
        assembly {
            part := mload(add(data, 32))
        }
    }

    function sliceTransform(
        bytes memory data,
        uint256 start,
        uint256 length,
        bool removeFirstNibble
    )
        pure internal returns(bytes memory)
    {
        uint256 slots = length / 32;
        uint256 rest = (length % 32) * 8;
        uint256 pos = 32;
        uint256 si = 0;
        uint256 source;
        bytes memory newdata = new bytes(length);
        assembly {
            source := add(start, data)

            if removeFirstNibble {
                mstore(
                    add(newdata, pos),
                    shr(4, shl(4, mload(add(source, pos))))
                )
                si := 1
                pos := add(pos, 32)
            }

            for {let i := si} lt(i, slots) {i := add(i, 1)} {
                mstore(add(newdata, pos), mload(add(source, pos)))
                pos := add(pos, 32)
            }
            mstore(add(newdata, pos), shl(
                rest,
                shr(rest, mload(add(source, pos)))
            ))
        }
    }

    function getHash(bytes memory data) public pure returns (bytes32 hash) {
        return keccak256(data);
    }

    function getNibbles(bytes1 b) internal pure returns (bytes1 nibble1, bytes1 nibble2) {
        assembly {
                nibble1 := shr(4, b)
                nibble2 := shr(4, shl(4, b))
            }
    }

    function expandKeyEven(bytes memory data) internal pure returns (bytes memory) {
        uint256 length = data.length * 2;
        bytes memory expanded = new bytes(length);

        for (uint256 i = 0 ; i < data.length; i++) {
            (bytes1 nibble1, bytes1 nibble2) = getNibbles(data[i]);
            expanded[i * 2] = nibble1;
            expanded[i * 2 + 1] = nibble2;
        }
        return expanded;
    }

    function expandKeyOdd(bytes memory data) internal pure returns(bytes memory) {
        uint256 length = data.length * 2 - 1;
        bytes memory expanded = new bytes(length);
        expanded[0] = data[0];

        for (uint256 i = 1 ; i < data.length; i++) {
            (bytes1 nibble1, bytes1 nibble2) = getNibbles(data[i]);
            expanded[i * 2 - 1] = nibble1;
            expanded[i * 2] = nibble2;
        }
        return expanded;
    }
}

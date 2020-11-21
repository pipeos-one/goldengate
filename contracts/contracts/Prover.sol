pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./RLPEncode.sol";
import "./RLPDecode.sol";
import "./EthereumDecoder.sol";

interface EthereumClient {
    function getBlockHash(uint256 height) view external returns (bytes32 hash);
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

    function verifyStorage(
        EthereumDecoder.BlockHeader memory header,
        MerkleProof memory accountProof,
        MerkleProof memory storageProof
    ) view public returns (bytes memory)
    {
        EthereumDecoder.Account memory account = EthereumDecoder.toAccount(accountProof.expectedValue);

        // Check block hash is hash(rlp(blockData))
        bytes32 blockHash = getBlockHash(header);
        // require(blockHash == header.hash, "Header data or hash invalid");

        // Check block hash was registered in light client
        bytes32 blockHashClient = client.getBlockHash(header.number);
        require(blockHashClient > 0, "Unregistered block hash");

        // Check storage root is part of the account
        require(storageProof.expectedRoot == account.storageRoot, "Account storageRoot or storage proof invalid. ");

        // check account root
        // TODO meld two verification - they share indexes and header data

        // Check proofs are valid
        bytes memory a = verifyTrieProof(accountProof);
        bytes memory b = verifyTrieProof(storageProof);
        return abi.encodePacked(a, b);
    }

    function verifyBalance(
        EthereumDecoder.BlockHeader memory header,
        MerkleProof memory txdata,
        MerkleProof memory receiptdata,
        uint256 value
    ) view public returns (bytes memory)
    {
        EthereumDecoder.Transaction memory transaction = EthereumDecoder.toTransaction(txdata.expectedValue);
        EthereumDecoder.TransactionReceiptTrie memory receipt = EthereumDecoder.toReceipt(receiptdata.expectedValue);

        // Check block hash is hash(rlp(blockData))
        bytes32 blockHash = getBlockHash(header);
        require(blockHash == header.hash, "Header data or hash invalid");

        // Check block hash was registered in light client
        bytes32 blockHashClient = client.getBlockHash(header.number);
        require(blockHashClient > 0, "Unregistered block hash");

        // decode receipt status and check it is true
        require(receipt.status == 1, "Transaction receipt status failed");

        // TODO: check sender sent transaction
        require(transaction.value == value, "Wrong transaction value");

        // TODO meld two verification - they share indexes and header data

        // TODO check storage proofs -> storageHash

        // Check proofs are valid
        bytes memory a = verifyTrieProof(txdata);
        bytes memory b = verifyTrieProof(receiptdata);
        return abi.encodePacked(a, b);
    }

    function verifyTrieProof(
        MerkleProof memory data
    ) pure public returns (bool correct)
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
    ) pure public returns (bool correct)
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
    ) pure public returns (bool correct)
    {
        bytes memory nodekey = dec.next().toBytes();
        bytes memory nodevalue = dec.next().toBytes();
        uint256 prefix;
        assembly {
            let first := shr(248, mload(add(nodekey, 32)))
            prefix := shr(4, first)
        }

        if (prefix == 2) {
            return verifyTrieProofLeafEven(nodekey, nodevalue, data);
        }
        else if (prefix == 3) {
            return verifyTrieProofLeafOdd(nodekey, nodevalue, data);
        }
        else if (prefix == 0) {
            return verifyTrieProofExtensionEven(nodekey, nodevalue, data);
        }
        else if (prefix == 1) {
        }   return verifyTrieProofExtensionOdd(nodekey, nodevalue, data);

        revert("Invalid proof");
    }


    function verifyTrieProofLeafEven(
        bytes memory nodekey,
        bytes memory nodevalue,
        MerkleProof memory data
    ) pure public returns (bool correct)
    {
        // even leaf node
        uint256 length = nodekey.length - 1;
        // bytes memory actualKey = slice(nodekey, 33, length);
        // bytes memory restKey = slice(data.key, 32 + data.keyIndex, length);

        bytes memory actualKey = new bytes(length);
        bytes memory restKey = new bytes(length * 2);
        bytes memory key = data.key;
        uint256 keyIndex = data.keyIndex;
        assembly {
            mstore(add(actualKey, 32), shr(4, shl(4, mload(add(nodekey, 33)))))
            mstore(add(restKey, 32), mload(add(key, add(32, keyIndex))))
            mstore(add(restKey, 64), mload(add(key, add(64, keyIndex))))
        }

        if (keccak256(data.expectedValue) == keccak256(nodevalue)) {
            if (keccak256(actualKey) == keccak256(restKey)) return hex'1144';
            if (keccak256(expandKeyEven(actualKey)) == keccak256(restKey)) return hex'1144';
        }
        if (data.expectedValue.length == 0) return true;
        else return false;
    }

    function verifyTrieProofLeafOdd(
        bytes memory nodekey,
        bytes memory nodevalue,
        MerkleProof memory data
    ) pure public returns (bool correct)
    {
        // odd leaf node
        bytes memory actualKey = new bytes(nodekey.length);
        bytes memory restKey = new bytes((data.key.length - data.keyIndex) * 2);
        bytes memory key = data.key;
        uint256 keyIndex = data.keyIndex;
        assembly {
            mstore(add(actualKey, 32), shr(4, shl(4, mload(add(nodekey, 32)))))
            mstore(add(restKey, 32), mload(add(key, add(32, keyIndex))))
            mstore(add(restKey, 64), mload(add(key, add(64, keyIndex))))
        }

        if (keccak256(data.expectedValue) == keccak256(nodevalue)) {
            if (keccak256(actualKey) == keccak256(restKey)) return hex'1155';
            if (keccak256(expandKeyOdd(actualKey)) == keccak256(restKey)) return hex'1155';
        }
        if (data.expectedValue.length == 0) return true;
        else return false;
    }

    function verifyTrieProofExtensionEven(
        bytes memory nodekey,
        bytes memory nodevalue,
        MerkleProof memory data
    ) pure public returns (bool correct)
    {
        // even extension node
        uint256 extensionLength = nodekey.length - 1;
        bytes memory shared_nibbles = slice(nodekey, 33, extensionLength);
        bytes memory restKey = slice(data.key, 32 + data.keyIndex, extensionLength);

        if (keccak256(shared_nibbles) == keccak256(restKey)) {
            data.expectedRoot = b2b32(nodevalue);
            data.keyIndex += extensionLength;
            data.proofIndex += 1;
            return verifyTrieProof(data);
        }
        if (data.expectedValue.length == 0) return true;
        else return false;
    }

    function verifyTrieProofExtensionOdd(
        bytes memory nodekey,
        bytes memory nodevalue,
        MerkleProof memory data
    ) pure public returns (bool correct)
    {

        // odd extension node
        uint256 extensionLength = nodekey.length;
        bytes memory shared_nibbles = new bytes(extensionLength);
        bytes memory restKey = new bytes(extensionLength);

        bytes memory key = data.key;
        uint256 keyIndex = data.keyIndex;

        assembly {
            mstore(add(shared_nibbles, 32), shr(4, shl(4, mload(add(nodekey, 32)))))
            mstore(add(restKey, 32), mload(add(key, add(32, keyIndex))))
        }

        if (keccak256(shared_nibbles) == keccak256(restKey)) {
            data.expectedRoot = b2b32(nodevalue);
            data.keyIndex += extensionLength;
            data.proofIndex += 1;
            return verifyTrieProof(data);
        }
        if (data.expectedValue.length == 0) return true;
        else return false;
    }

    function b2b32(bytes memory data) pure internal returns(bytes32 part) {
        assembly {
            part := mload(add(data, 32))
        }
    }

    function slice(bytes memory data, uint256 start, uint256 length) pure internal returns(bytes memory) {
        bytes memory newdata = new bytes(length);
        // TODO this is used for keys, which are max 64 bytes long when expanded
        // fixme precision
        assembly {
            mstore(add(newdata, 32), mload(add(data, add(32, start))))
            mstore(add(newdata, 64), mload(add(data, add(64, start))))
        }
        return newdata;
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

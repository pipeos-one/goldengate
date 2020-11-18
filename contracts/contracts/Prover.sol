pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./RLPEncode.sol";
import "./RLPDecode.sol";
import "./EthereumDecoder.sol";

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

    function verifyTrieProof(
        MerkleProof memory data
    ) pure public returns (bool correct)
    {
        // data.key = hex'0001';

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
        // get prefix and optional nibble from the first byte
        uint256 prefix;
        uint256 nibble;
        assembly {
            let first := shr(248, mload(add(nodekey, 32)))
            prefix := shr(4, first)
            nibble := and(first, 0x0f)
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
        bytes memory actualKey = slice(nodekey, 33, length);
        bytes memory restKey = slice(data.key, 32 + data.keyIndex, length);

        if (
            keccak256(actualKey) == keccak256(restKey)
            && keccak256(data.expectedValue) == keccak256(nodevalue)
        ) {
            return true;
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
        bytes memory restKey = new bytes(data.key.length - data.keyIndex);
        bytes memory key = data.key;
        uint256 keyIndex = data.keyIndex;
        assembly {
            mstore(add(actualKey, 32), shr(8, shl(8, mload(add(nodekey, 32)))))
            mstore(add(restKey, 32), mload(add(key, add(32, keyIndex))))
        }

        if (
            keccak256(actualKey) == keccak256(restKey)
            && keccak256(data.expectedValue) == keccak256(nodevalue)
        ) {
            return true;
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
            mstore(add(shared_nibbles, 32), shr(8, shl(8, mload(add(nodekey, 32)))))
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
        assembly {
            mstore(add(newdata, 32), mload(add(data, add(32, start))))
        }
        return newdata;
    }

    function getHash(bytes memory data) public pure returns (bytes32 hash) {
        return keccak256(data);
    }
}

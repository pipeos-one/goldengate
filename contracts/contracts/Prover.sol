pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./RLPEncode.sol";
import "./RLPDecode.sol";
import "./EthereumDecoder.sol";

contract Prover {
    using RLPDecode for RLPDecode.RLPItem;
    using RLPDecode for RLPDecode.Iterator;

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
        while(it.hasNext() && idx > 0) {
            it.next();
            idx --;
        }
        return it.next();
    }

    function verifyTrieProof(
        bytes32 expectedRoot,
        bytes memory key,
        bytes[] memory proof,
        uint256 keyIndex,
        uint256 proofIndex,
        bytes memory expectedValue
    ) pure public returns (bytes memory) // (bool correct)
    {
        bytes memory node = proof[proofIndex];

        RLPDecode.Iterator memory dec = RLPDecode.toRlpItem(node).iterator();

        if (keyIndex == 0) {
            require(keccak256(node) == expectedRoot);
        }
        else if (node.length < 32) {
            bytes32 root = bytes32(dec.next().toUint());
            require(root == expectedRoot);
        }
        else {
            require(keccak256(node) == expectedRoot);
        }

        uint256 numberItems = RLPDecode.numItems(dec.item);

        // branch
        if (numberItems == 17) {
            if (keyIndex >= key.length) {
                RLPDecode.RLPItem memory item = nthRlpItem(RLPDecode.toRlpItem(node).iterator(), numberItems - 1);
                if (keccak256(item.toBytes()) == keccak256(expectedValue)) {
                    // return true;
                    return hex"17";
                }
                else revert("Incorrect proof");
            }
            else {
                uint256 index = uint256(uint8(key[keyIndex]));
                bytes memory _newExpectedRoot = nthRlpItem(RLPDecode.toRlpItem(node).iterator(), index).toBytes();
                bytes32 newExpectedRoot;
                assembly {
                    newExpectedRoot := mload(_newExpectedRoot)
                }
                if (!(newExpectedRoot.length == 0)) {
                    return verifyTrieProof(
                        newExpectedRoot,
                        key,
                        proof,
                        keyIndex + 1,
                        proofIndex + 1,
                        expectedValue
                    );
                }
            }
        }

        // leaf / extension
        if (numberItems == 2) {
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
                // even leaf node
                // FIX allocation overstepping
                bytes memory actualKey = new bytes(nodekey.length - 1);
                bytes memory restKey = new bytes(key.length - keyIndex);
                assembly {
                    mstore(add(actualKey, 32), mload(add(nodekey, 33)))
                    mstore(add(restKey, 32), mload(add(key, add(32, keyIndex))))
                }

                if (keccak256(actualKey) == keccak256(restKey) && keccak256(expectedValue) == keccak256(nodevalue)) {
                    // return true;
                    return hex"02";
                }
            }
            else if (prefix == 3) {
                // odd leaf node
                bytes memory actualKey = new bytes(nodekey.length);
                bytes memory restKey = new bytes(key.length - keyIndex);
                assembly {
                    let maxkey := mload(add(nodekey, 32))
                    mstore(add(actualKey, 32), shr(8, shl(8, maxkey)))
                    mstore(add(restKey, 32), mload(add(key, add(32, keyIndex))))
                }

                if (keccak256(actualKey) == keccak256(restKey) && keccak256(expectedValue) == keccak256(nodevalue)) {
                    // return true;
                    return hex"03";
                }
            }
            else if (prefix == 0) {
                // even extension node
                uint256 extensionLength = nodekey.length - 1;
                bytes memory shared_nibbles = new bytes(extensionLength);
                bytes memory restKey = new bytes(extensionLength);
                assembly {
                    mstore(add(shared_nibbles, 32), mload(add(nodekey, 33)))
                    mstore(add(restKey, 32), mload(add(key, add(32, keyIndex))))
                }

                if (keccak256(shared_nibbles) == keccak256(restKey)) {
                    bytes32 newExpectedRoot;
                    assembly {
                        newExpectedRoot := mload(add(nodevalue, 32))
                    }
                    return verifyTrieProof(
                        newExpectedRoot,
                        key,
                        proof,
                        keyIndex + extensionLength,
                        proofIndex + 1,
                        expectedValue
                    );
                }
            }
            else if (prefix == 1) {
                // odd extension node
                uint256 extensionLength = nodekey.length;
                bytes memory shared_nibbles = new bytes(extensionLength);
                bytes memory restKey = new bytes(extensionLength);

                assembly {
                    let maxkey := mload(add(nodekey, 32))
                    mstore(add(shared_nibbles, 32), shr(8, shl(8, maxkey)))
                    mstore(add(restKey, 32), mload(add(key, add(32, keyIndex))))
                }

                if (keccak256(shared_nibbles) == keccak256(restKey)) {
                    bytes32 newExpectedRoot;
                    assembly {
                        newExpectedRoot := mload(add(nodevalue, 32))
                    }
                    return verifyTrieProof(
                        newExpectedRoot,
                        key,
                        proof,
                        keyIndex + extensionLength,
                        proofIndex + 1,
                        expectedValue
                    );
                }
            }
            else {
                revert("Invalid proof");
            }
        }

        if (expectedValue.length == 0) {
            // return true;
            return hex"1111";
        }
        else {
            // return false;
            return hex"0000";
        }
    }

    function getMerkleRoot(bytes memory merkle_tree_leaves)
        pure
        internal
        returns (bytes32)
    {
        uint256 length = merkle_tree_leaves.length;

        // each merkle_tree lock component has this form:
        // (locked_amount || expiration_block || secrethash) = 3 * 32 bytes
        require(length % 96 == 0);

        uint256 i;
        uint256 unlocked_amount;
        bytes32 lockhash;
        bytes32 merkle_root;

        bytes32[] memory merkle_layer = new bytes32[](length / 96 + 1);

        for (i = 32; i < length; i += 96) {
            (lockhash, unlocked_amount) = getLockDataFromMerkleTree(merkle_tree_leaves, i);
            merkle_layer[i / 96] = lockhash;
        }

        length /= 96;

        while (length > 1) {
            if (length % 2 != 0) {
                merkle_layer[length] = merkle_layer[length - 1];
                length += 1;
            }

            for (i = 0; i < length - 1; i += 2) {
                if (merkle_layer[i] == merkle_layer[i + 1]) {
                    lockhash = merkle_layer[i];
                } else if (merkle_layer[i] < merkle_layer[i + 1]) {
                    lockhash = keccak256(abi.encodePacked(merkle_layer[i], merkle_layer[i + 1]));
                } else {
                    lockhash = keccak256(abi.encodePacked(merkle_layer[i + 1], merkle_layer[i]));
                }
                merkle_layer[i / 2] = lockhash;
            }
            length = i / 2;
        }

        merkle_root = merkle_layer[0];

        return merkle_root;
    }

    function getLockDataFromMerkleTree(bytes memory merkle_tree_leaves, uint256 offset)
        pure
        internal
        returns (bytes32, uint256)
    {
        uint256 expiration_block;
        uint256 locked_amount;
        bytes32 secrethash;
        bytes32 lockhash;

        if (merkle_tree_leaves.length <= offset) {
            return (lockhash, 0);
        }

        assembly {
            expiration_block := mload(add(merkle_tree_leaves, offset))
            locked_amount := mload(add(merkle_tree_leaves, add(offset, 32)))
            secrethash := mload(add(merkle_tree_leaves, add(offset, 64)))
        }

        // Calculate the lockhash for computing the merkle root
        lockhash = keccak256(abi.encodePacked(expiration_block, locked_amount, secrethash));

        return (lockhash, locked_amount);
    }
}

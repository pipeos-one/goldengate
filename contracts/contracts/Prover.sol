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
}

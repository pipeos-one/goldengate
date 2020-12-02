pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/MPT.sol";

contract MPTWrap {
    using MPT for MPT.MerkleProof;

    function verifyTrieProof(MPT.MerkleProof memory data) pure public returns (bool) {
        return data.verifyTrieProof();
    }
}

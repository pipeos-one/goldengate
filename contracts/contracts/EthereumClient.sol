pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./EthereumDecoder.sol";

contract EthereumClient {
    uint256 lastBlockHeight = 0;

    mapping(uint256 => bytes32) blockHashes;

    event BlockAdded(uint256 indexed height, bytes32 indexed hash);

    constructor(bytes32 hash0) public {
        blockHashes[0] = hash0;
    }

    function getBlockHash(uint256 height) view public returns (bytes32 hash) {
        return blockHashes[height];
    }

    function addBlock(EthereumDecoder.BlockHeader memory header) public {
        require(header.number == lastBlockHeight + 1, "Wrong height");
        require(header.parentHash == blockHashes[lastBlockHeight], "Parent not found");
        require(header.hash == EthereumDecoder.getBlockHash(header), "Invalid hash");
        // verify difficulty
        _addBlock(header.number, header.hash);
    }

    function _addBlock(uint256 height, bytes32 hash) internal {
        blockHashes[height] = hash;
        lastBlockHeight = height;
        emit BlockAdded(height, hash);
    }
}

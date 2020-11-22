pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./EthereumDecoder.sol";

contract LightClient {
    uint256 public lastBlockHeight = 0;

    mapping(uint256 => bytes32) public blockHashes;

    event BlockAdded(uint256 indexed height, bytes32 indexed hash);

    constructor(bytes32 hash0, uint256 height) public {
        blockHashes[height] = hash0;
        lastBlockHeight = height;
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

    // Only development!
    function _addBlock(uint256 height, bytes32 hash) public {
        blockHashes[height] = hash;
        lastBlockHeight = height;
        emit BlockAdded(height, hash);
    }
}

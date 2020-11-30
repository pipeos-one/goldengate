pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../EthereumDecoder.sol";

contract LightClientMock {
    mapping(uint256 => bytes32) public blockHashes;

    function getValidBlockHash(uint256 number) view public returns (bytes32 hash) {
        return blockHashes[number];
    }

    function _addBlock(EthereumDecoder.BlockHeader memory header) public {
        blockHashes[header.number] = header.hash;
    }
}

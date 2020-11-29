pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./EthereumDecoder.sol";

contract LightClient {
    uint256 public minNumberBlocks;
    uint256 public registerPeriod;
    uint256 public totalDifficulty;
    EthereumDecoder.BlockHeader lastValidBlock;
    EthereumDecoder.BlockHeader lastBlock;

    mapping(uint256 => bytes32) public blockHashes;

    event BlockAdded(uint256 indexed height, bytes32 indexed hash);

    constructor(uint256 _minNumberBlocks, EthereumDecoder.BlockHeader memory _lastValidBlock) public {
        minNumberBlocks = _minNumberBlocks;
        lastValidBlock = _lastValidBlock;
        blockHashes[lastValidBlock.number] = lastValidBlock.hash;
    }

    function getBlockHash(uint256 height) view public returns (bytes32 hash) {
        return blockHashes[height];
    }

    function addBlocks(EthereumDecoder.BlockHeader[] memory headers) public {
        EthereumDecoder.BlockHeader memory _lastBlock = lastValidBlock;
        for (uint256 i = 0; i < headers.length; i++) {
            EthereumDecoder.BlockHeader memory header = headers[i];
            require(header.number == _lastBlock.number + 1, "Wrong number");
            require(header.parentHash == _lastBlock.hash, "Parent not found");
            require(header.hash == EthereumDecoder.getBlockHash(header), "Invalid hash");
            // require(header.timestamp < _lastBlock.timestamp, "Invalid timestamp");
            require(header.extraData.length <= 32, "Invalid extraData");
            require(header.gasUsed < header.gasLimit, "Invalid gas");
            require(header.gasLimit > _lastBlock.gasLimit * 1023 / 1024, "Invalid gasLimit1");
            require(header.gasLimit < _lastBlock.gasLimit * 1025 / 1024, "Invalid gasLimit2");
            require(header.gasLimit > 5000, "Invalid gasLimit3");
            // require(header.difficulty < header.difficulty * 101 / 100, "Invalid difficulty1");
            // require(header.difficulty > header.difficulty * 99 / 100, "Invalid difficulty2");

            _lastBlock = header;
            _addBlock(header);
        }
    }

    function _addBlock(EthereumDecoder.BlockHeader memory header) public {
        blockHashes[header.number] = header.hash;
        lastValidBlock = header;
        emit BlockAdded(header.number, header.hash);
    }
}

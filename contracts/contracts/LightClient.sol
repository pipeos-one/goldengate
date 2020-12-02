pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./lib/EthereumDecoder.sol";

contract LightClient {
    uint256 public minNumberBlocks;
    uint256 public maxNumberBlocks;
    uint256 public registerPeriod;
    uint256 public blockTick;
    BlockHeaderMin public lastValidBlock;
    BlockHeaderMin public lastBlock;

    mapping(uint256 => bytes32) public blockHashes;

    struct BlockHeaderMin {
        bytes32 hash;
        bytes32 parentHash;
        uint256 difficulty;   // remove
        uint256 number;
        uint256 gasLimit;
        uint256 gasUsed;
        uint256 timestamp;
        uint256 totalDifficulty;
    }

    event BlockAdded(uint256 indexed number, bytes32 indexed hash);
    event FinalBlockChanged(uint256 indexed number, bytes32 indexed hash);

    constructor(uint256 _minNumberBlocks, uint256 _maxNumberBlocks, uint256 _registerPeriod, BlockHeaderMin memory _lastValidBlock) public {
        minNumberBlocks = _minNumberBlocks;
        maxNumberBlocks = _maxNumberBlocks;
        registerPeriod = _registerPeriod;
        lastValidBlock = _lastValidBlock;
        blockTick = lastValidBlock.number;
        blockHashes[lastValidBlock.number] = lastValidBlock.hash;
    }

    function getValidBlockHash(uint256 number) view public returns (bytes32 hash) {
        return number <= blockTick ? blockHashes[number] : bytes32(0);
    }

    function getBlockHash(uint256 number) view public returns (bytes32 hash) {
        return blockHashes[number];
    }

    function tick() public {
        if (lastBlock.number > blockTick + registerPeriod) {
            // Finalize 1 block
            blockTick += 1;
            emit BlockAdded(blockTick, getBlockHash(blockTick));

            // tick();
        }
    }

    function updateLastValidBlock(EthereumDecoder.BlockHeader memory header) public {
        require(header.number <= blockTick, "Cannot update invalid block");
        require(header.hash == EthereumDecoder.getBlockHash(header), "Invalid hash");
        require(header.hash == getBlockHash(header.number), "Hash different than expected");
        lastValidBlock = fullToMin(header);
        emit FinalBlockChanged(header.number, header.hash);
        tick();
    }

    // No batch of blocks is marked valid until registerPeriod passes
    // They are kept in temporary storage and compared with other proposals
    function addBlocks(EthereumDecoder.BlockHeader[] memory headers) public {
        require(headers.length >= minNumberBlocks && headers.length <= maxNumberBlocks, "Invalid number of blocks");

        bytes32[] memory newhashes = new bytes32[](headers.length);
        uint256 commonBlockNumber;

        BlockHeaderMin memory _lastBlock = lastValidBlock;
        for (uint256 i = 0; i < headers.length; i++) {
            EthereumDecoder.BlockHeader memory header = headers[i];

            // Continue until we find the next block after the last valid block
            if (header.number < _lastBlock.number + 1) continue;

            require(header.number == _lastBlock.number + 1, "Wrong number");
            require(header.parentHash == _lastBlock.hash, "Parent not found");
            require(header.hash == EthereumDecoder.getBlockHash(header), "Invalid hash");
            // require(header.timestamp < _lastBlock.timestamp, "Invalid timestamp");
            // For PoW systems
            // require(header.extraData.length <= 32, "Invalid extraData");
            require(header.gasUsed < header.gasLimit, "Invalid gas");
            require(header.gasLimit > _lastBlock.gasLimit * 1023 / 1024, "Invalid gasLimit1");
            require(header.gasLimit < _lastBlock.gasLimit * 1025 / 1024, "Invalid gasLimit2");
            require(header.gasLimit > 5000, "Invalid gasLimit3");
            // require(header.difficulty < header.difficulty * 101 / 100, "Invalid difficulty1");
            // require(header.difficulty > header.difficulty * 99 / 100, "Invalid difficulty2");

            require(header.totalDifficulty == header.difficulty + _lastBlock.totalDifficulty, "Invalid totalDifficulty");

            _lastBlock = fullToMin(header);
            newhashes[i] = header.hash;
            if (header.hash == getBlockHash(header.number)) {
                commonBlockNumber = header.number;
            }
        }

        // The header is valid. We check if another previous proposal exists
        // If previous proposal has same length & >> difficulty, we choose that one
        if (_lastBlock.totalDifficulty < lastBlock.totalDifficulty && _lastBlock.number <= lastBlock.number) {
            revert("Fork with bigger total difficulty exists");
        }

        // Here we assume that this is the best proposal
        uint256 startCopy = commonBlockNumber > 0 ? commonBlockNumber : (blockTick + 1);

        uint256 lastindex = startCopy - headers[0].number;
        registerProposal(_lastBlock, newhashes, lastindex);
    }

    function registerProposal(BlockHeaderMin memory _lastBlock, bytes32[] memory _hashes, uint256 _start) internal {
        uint256 startBlock = lastValidBlock.number + 1;
        for (uint256 i = _start; i < _hashes.length; i++) {
            blockHashes[startBlock + i] = _hashes[i];
        }
        lastBlock = _lastBlock;
    }

    function fullToMin(EthereumDecoder.BlockHeader memory header) pure internal returns (BlockHeaderMin memory minHeader) {
        minHeader.hash = header.hash;
        minHeader.parentHash = header.parentHash;
        minHeader.difficulty = header.difficulty;
        minHeader.number = header.number;
        minHeader.gasLimit = header.gasLimit;
        minHeader.gasUsed = header.gasUsed;
        minHeader.timestamp = header.timestamp;
        minHeader.totalDifficulty = header.totalDifficulty;
    }
}

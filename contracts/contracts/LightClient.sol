pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./interface/iLightClient.sol";

contract LightClient is iLightClient {
    uint256 minBatchCount;
    uint256 maxBatchCount;
    uint256 confirmationDelay;
    uint256 lastConfirmed;
    BlockHeaderMin public lastConfirmedHeader;
    BlockHeaderMin public lastHeader;

    mapping(uint256 => bytes32) blockHashes;

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

    // event BlockAdded(uint256 indexed number, bytes32 indexed hash);
    // event FinalBlockChanged(uint256 indexed number, bytes32 indexed hash);

    constructor(uint256 _minBatchCount, uint256 _maxBatchCount, uint256 _confirmationDelay, BlockHeaderMin memory _lastConfirmedHeader) public {
        minBatchCount = _minBatchCount;
        maxBatchCount = _maxBatchCount;
        confirmationDelay = _confirmationDelay;
        lastConfirmedHeader = _lastConfirmedHeader;
        lastConfirmed = lastConfirmedHeader.number;
        blockHashes[lastConfirmedHeader.number] = lastConfirmedHeader.hash;
    }

    function getMinBatchCount() view public override returns (uint256 count) {
        return minBatchCount;
    }

    function getMaxBatchCount() view public override returns (uint256 count) {
        return maxBatchCount;
    }

    function getConfirmationDelay() view public override returns (uint256 delay) {
        return confirmationDelay;
    }

    function getLastConfirmed() view public override returns (uint256 blockNumber) {
        return lastConfirmed;
    }

    function getLastVerifiable() view public override returns (uint256 blockNumber) {
        return lastConfirmedHeader.number;
    }

    function getBlockHash(uint256 number) view public override returns (bytes32 hash) {
        return blockHashes[number];
    }

    function getConfirmedBlockHash(uint256 number) view public override returns (bytes32 hash) {
        return number <= lastConfirmed ? blockHashes[number] : bytes32(0);
    }

    function tick() public override {
        if (lastHeader.number > lastConfirmed + confirmationDelay) {
            // Finalize 1 block
            lastConfirmed += 1;
            emit BlockAdded(lastConfirmed, getBlockHash(lastConfirmed));

            // tick();
        }
    }

    function updateLastVerifiableHeader(EthereumDecoder.BlockHeader memory header) public override {
        require(header.number <= lastConfirmed, "Cannot update invalid block");
        require(header.hash == EthereumDecoder.getBlockHash(header), "Invalid hash");
        require(header.hash == getBlockHash(header.number), "Hash different than expected");
        lastConfirmedHeader = fullToMin(header);
        emit FinalBlockChanged(header.number, header.hash);
        tick();
    }

    // No batch of blocks is marked valid until confirmationDelay passes
    // They are kept in temporary storage and compared with other proposals
    function addBlocks(EthereumDecoder.BlockHeader[] memory headers) public override {
        require(headers.length >= minBatchCount && headers.length <= maxBatchCount, "Invalid number of blocks");

        bytes32[] memory newhashes = new bytes32[](headers.length);
        uint256 commonBlockNumber;

        BlockHeaderMin memory _lastHeader = lastConfirmedHeader;
        for (uint256 i = 0; i < headers.length; i++) {
            EthereumDecoder.BlockHeader memory header = headers[i];

            // Continue until we find the next block after the last valid block
            if (header.number < _lastHeader.number + 1) continue;

            require(header.number == _lastHeader.number + 1, "Wrong number");
            require(header.parentHash == _lastHeader.hash, "Parent not found");
            require(header.hash == EthereumDecoder.getBlockHash(header), "Invalid hash");
            // require(header.timestamp < _lastHeader.timestamp, "Invalid timestamp");
            // For PoW systems
            // require(header.extraData.length <= 32, "Invalid extraData");
            require(header.gasUsed < header.gasLimit, "Invalid gas");
            require(header.gasLimit > _lastHeader.gasLimit * 1023 / 1024, "Invalid gasLimit1");
            require(header.gasLimit < _lastHeader.gasLimit * 1025 / 1024, "Invalid gasLimit2");
            require(header.gasLimit > 5000, "Invalid gasLimit3");
            // require(header.difficulty < header.difficulty * 101 / 100, "Invalid difficulty1");
            // require(header.difficulty > header.difficulty * 99 / 100, "Invalid difficulty2");

            require(header.totalDifficulty == header.difficulty + _lastHeader.totalDifficulty, "Invalid totalDifficulty");

            _lastHeader = fullToMin(header);
            newhashes[i] = header.hash;
            if (header.hash == getBlockHash(header.number)) {
                commonBlockNumber = header.number;
            }
        }

        // The header is valid. We check if another previous proposal exists
        // If previous proposal has same length & >> difficulty, we choose that one
        if (_lastHeader.totalDifficulty < lastHeader.totalDifficulty && _lastHeader.number <= lastHeader.number) {
            revert("Fork with bigger total difficulty exists");
        }

        // Here we assume that this is the best proposal
        uint256 startCopy = commonBlockNumber > 0 ? commonBlockNumber : (lastConfirmed + 1);

        uint256 lastindex = startCopy - headers[0].number;
        registerProposal(_lastHeader, newhashes, lastindex);
    }

    function registerProposal(BlockHeaderMin memory _lastHeader, bytes32[] memory _hashes, uint256 _start) internal {
        uint256 startBlock = lastConfirmedHeader.number + 1;
        for (uint256 i = _start; i < _hashes.length; i++) {
            blockHashes[startBlock + i] = _hashes[i];
        }
        lastHeader = _lastHeader;
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

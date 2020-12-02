pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../lib/EthereumDecoder.sol";

interface iLightClient {
    event BlockAdded(uint256 indexed number, bytes32 indexed hash);
    event FinalBlockChanged(uint256 indexed number, bytes32 indexed hash);

    function getMinBatchCount() view external returns (uint256 count);
    function getMaxBatchCount() view external returns (uint256 count);
    function getConfirmationDelay() view external returns (uint256 delay);
    function getLastConfirmed() view external returns (uint256 blockNumber);
    function getLastVerifiable() view external returns (uint256 blockNumber);

    function getBlockHash(uint256 number) view external returns (bytes32 hash);
    function getConfirmedBlockHash(uint256 number) view external returns (bytes32 hash);

    function tick() external;
    function updateLastVerifiableHeader(EthereumDecoder.BlockHeader memory header) external;
    function addBlocks(EthereumDecoder.BlockHeader[] memory headers) external;
}

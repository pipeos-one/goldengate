pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./Prover.sol";

contract ProverCorrelated is Prover {
    address public correlatedProver;
    mapping(bytes32 => CorrelatedAction) public actions;


    struct CorrelatedAction {
        address to;
        bytes4 sig;
    }

    event ActionInitiated(bytes32 indexed id);

    constructor(address bridgeClient) Prover(bridgeClient) {}

    function registerProver(address _prover) public {
        correlatedProver = _prover;
    }

    function addAction(CorrelatedAction memory action1, CorrelatedAction memory action2) public {
        actions[keccak256(abi.encode(action1.to, action1.sig))] = action2;
    }

    function initiate(address to, bytes4 sig, bytes memory data) public returns (bytes memory) {
        (bool success, bytes memory result) = to.call(abi.encodePacked(sig, data));
        require(success, "Tx reverted");

        CorrelatedAction memory action = actions[keccak256(abi.encode(to, sig))];
        bytes32 emittedKey = keccak256(abi.encode(action.to, action.sig, data));
        emit ActionInitiated(emittedKey);

        return result;
    }

    function correlate(
        EthereumDecoder.BlockHeader memory header,
        MPT.MerkleProof memory receiptdata,
        bytes memory logdata,
        uint256 logIndex,
        address to,
        bytes4 sig,
        bytes memory data
    )
        public returns (bytes memory)
    {
        (bool valid, string memory reason) = verifyHeader(header);
        if (!valid) revert(reason);

        (valid, reason) = verifyReceipt(header, receiptdata);
        if (!valid) revert(reason);

        (valid, reason) = verifyLog(receiptdata, logdata, logIndex);
        if (!valid) revert(reason);

        EthereumDecoder.Log memory log = EthereumDecoder.toReceiptLog(logdata);

        require(log.contractAddress == correlatedProver, "Event emitter not recognized");

        bytes32 key = keccak256(abi.encode(to, sig, data));
        require(key == log.topics[1], "Event index doesn't match data hash");

        // TODO replay protection

        (bool success, bytes memory result) = to.call(abi.encodePacked(sig, data));
        require(success, "Diverged transaction status");

        return result;
    }

}

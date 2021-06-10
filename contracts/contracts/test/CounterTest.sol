pragma solidity ^0.7.0;

// Used to mimic a Counter contract with the same address, on 2 chains
// Syncing state transaction goes through a proxy
contract CounterTest {
    int32 public count = 5;
    int32 public count2 = 5;
    address public proxy;

    event LogChange(bytes message);
    event LogChange2(bytes message);

    constructor(address _proxy) {
        proxy = _proxy;
    }

    function incrementCounter(int32 value) public {
        if (msg.sender == proxy) {
            count2 += value;
            emit LogChange2(abi.encodePacked("Counter is now: ", count2));
        } else {
            count += value;
            emit LogChange(abi.encodePacked("Counter is now: ", count));
        }
    }

    function decrementCounter(int32 value) public {
        if (msg.sender == proxy) {
            count2 -= value;
            emit LogChange2(abi.encodePacked("Counter is now: ", count2));
        } else {
            count -= value;
            emit LogChange(abi.encodePacked("Counter is now: ", count));
        }
    }

    function getCounter() view public returns(int32) {
        return count;
    }

    function resetCounter(int32 value) payable public {
        require(uint256(value) == msg.value);
        if (msg.sender == proxy) {
            count2 = value;
            emit LogChange2(abi.encodePacked("Counter is reset!"));
        } else {
            count = value;
            emit LogChange(abi.encodePacked("Counter is reset!"));
        }
    }

    function getCodeHash() view public returns(bytes32 codeHash) {
        address target = address(this);
        assembly {
            codeHash := extcodehash(target)
        }
    }
}

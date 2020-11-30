pragma solidity ^0.7.0;

contract Counter {
    int32 public count = 5;

    event LogChange(bytes message);

    function incrementCounter(int32 value) public {
        count += value;
        emit LogChange(abi.encodePacked("Counter is now: ", count));
    }

    function decrementCounter(int32 value) public {
        count -= value;
        emit LogChange(abi.encodePacked("Counter is now: ", count));
    }

    function getCounter() view public returns(int32) {
        return count;
    }

    function resetCounter(int32 value) payable public {
        require(uint256(value) == msg.value);
        count = value;
        emit LogChange(abi.encodePacked("Counter is reset!"));
    }
}

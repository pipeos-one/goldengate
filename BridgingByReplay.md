# Golden Gate Bridging by Replay

## Light Client

If the chain does not benefit from IBC, it needs a light client of each of the bridged chains.

## IBC

For EVM, an IBC precompile can play the role of a light client. Build order (on each chain):

- Singleton Factory
- Singleton Proxy with IBC semaphores
- Singleton ACL
- other singleton contracts (to be remotely played)

## Singleton Contracts

The transaction reply pattern can be implemented on EVM<->EVM bridge by using the same address of contracts and nonce synch across pairs of chains.
Such enforcing has to follow:

- controlled creation of contracts (eventually synchoronized creation)
- controlled nonce and order of synchronized transactions

## ACL Contracts

- for ensuring required balance / eventual slashing

## Proxy Contracts

- redirect transactions to the contracts where they need to execute
- maintain nonce sync or
- maintain state hash conform with "Abstracted Blockchains" theory

## IBC Precompile

- maintains one version of the state hash conform with "Abstracted Blockchains" theory

## ERC20, EIP721, Asset minting contracts

These contracts are not compatible directly with replay bridging, but they can become compatible by adapter contracts (that forward transactions).
Also replay-compatible protocols that correspond to these standards should be standardized (for gas saving).

### ERC20 -> ERC20-EGG

from https://eips.ethereum.org/EIPS/eip-20

All pure and view functions remain the same. Also the events:

- function name() public view returns (name: string)
- function symbol() public view returns (symbol: string)
- function decimals() public view returns (decimals: uint8)
- function totalSupply() public view returns (uint256)
- function balanceOf(address _owner) public view returns (uint256 balance)

- event Transfer(address indexed _from, address indexed _to, uint256 _value)
- event Approval(address indexed _owner, address indexed _spender, uint256 _value)

All mutable functions:

- function transfer(address _to, uint256 _value) public returns (bool success)
- function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
- function approve(address _spender, uint256 _value) public returns (bool success)
- function allowance(address _owner, address _spender) public view returns (uint256 remaining)

Become private and change their name to: _<function name> Example:

- function _transfer(address _to, uint256 _value) private returns (bool success)

The public mutable functions will be defined as:
  
```
function <function name>On(chain_ID, ...)...{
  uint256 chainID;
    assembly {
        chainID := chainid()
    }
  if (chainID == chain_ID) {
    _<function name>(...);
  }
}
```
Example:

```
function transferOn(uint chain_ID, address _to, uint256 _value) private returns (bool success){
  uint256 chainID;
  assembly {
      chainID := chainid()
  }
  if (chainID == chain_ID) {
    return _transfer(address _to, uint256 _value);
  }
  return 1;
}
  
```
  
In addition, we add a new function:
```
function transferTo(uint chain_ID, address _to, uint256 _value) private returns (bool success){
  _transfer( 0x0, _value);
  BridgeProxy.forePlay(encode(this.mintOn(chain_ID, _value)));
  return 1;
}
```

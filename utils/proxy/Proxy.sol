pragma solidity >=0.6.0 <0.8.0;

import '../basic/Address.sol';
/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
abstract contract Proxy {

  using Address for address payable;

  event DepositETH(address indexed sender, uint256 indexed amount);

  /**
  * @dev Tells the address of the implementation where every call will be delegated.
  * @return address of the implementation to which it will be delegated
  */
  function implementation() public virtual view returns (address);

  receive() external virtual payable {
    if(msg.value>0){
      emit DepositETH(msg.sender,msg.value);
    }
  }

  /**
  * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
  fallback () external payable  {
    address _impl = implementation();
    require(_impl != address(0), "Implementation is 0");

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize())
      let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
      let size := returndatasize()
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }

  function withdrawETHFromProxyInternal(address payable dest, uint256 amount) internal {
    dest.sendValue(amount);
  }
}

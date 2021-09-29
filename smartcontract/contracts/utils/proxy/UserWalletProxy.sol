
pragma solidity >=0.6.0 <0.8.0;

import './OwnedUpgradeabilityProxy.sol';
import '../../wallet/IUserWallet.sol';
import '../ownable/MultiOwnable.sol';

contract UserWalletProxy is MultiOwnable, IUserWallet{

  event TransferRequestFailed(address indexed dest, uint256 indexed userGasUsed, uint256 indexed amount, string assetName, bytes revertReason);
  event SubmitWithdrawFailed(address indexed dest, uint256 indexed userGasUsed, uint256 indexed amount, uint256 amountWithFee, string assetName, bytes revertReason);

  event DepositETH(address indexed sender, uint256 indexed amount);

  bytes32 private constant userWalletImplPosition = keccak256("net.eurus.implementation");
  uint256 private constant extraGasFee = 49000;
  /**
   * @dev Tells the address of the current implementation
   * @return impl address of the current implementation
   */
  function getUserWalletImplementation() public view returns (address impl) {
    bytes32 position = userWalletImplPosition;
    assembly {
      impl := sload(position)
    }
  }

  /**
   * @dev Sets the address of the current implementation
   * @param newImplementation address representing the new implementation to be set
   */
  function setUserWalletImplementation(address newImplementation) public onlyOwner{
    bytes32 position = userWalletImplPosition;
    assembly {
      sstore(position, newImplementation)
    }
  }


  function requestTransfer(address dest, string memory assetName, uint256 amount, bytes memory /*signature*/) public override{
      uint256 gasBegin = gasleft();
      address _impl = getUserWalletImplementation();
      require(_impl != address(0), "getUserWalletImplementation is 0");

      bytes memory ptr; 
      uint256 offset; 
      assembly {
          ptr := mload(0x40)
          calldatacopy(ptr, 0, calldatasize())
          let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
          let size := returndatasize()
          returndatacopy(ptr, 0, size)
          
          switch result
          case 0{
              
              if gt (size, 0) {

                offset := add ( ptr, 0x120)
                mstore(0x40, offset)
                ptr := add(ptr, 4)
                let lengthFieldLength := mload(ptr)
                ptr := add(ptr, lengthFieldLength)
              }
          }
          default{
            return(ptr, size)
          }
      }

      (bool isSuccess, bytes memory data) = _impl.delegatecall(abi.encodeWithSignature("getGasFeeWalletAddress()"));
      if (!isSuccess){
        revert('Unable to call getGetFeeWalletAddress');
      }

      address gasFeeAddress = bytesToAddress(data);
      address payable gasFeeWallet = payable(gasFeeAddress);
      uint256 gasUsed = gasBegin - gasleft()  + extraGasFee;
      gasFeeWallet.transfer(gasUsed * tx.gasprice);

      emit TransferRequestFailed(dest, gasUsed, amount, assetName, ptr);
      emit GasFeeTransferred(gasFeeWallet, gasUsed * tx.gasprice);
  }

  function submitWithdraw(address dest, uint256 withdrawAmount, uint256 amountWithFee, string memory assetName, bytes memory /*signature*/) public override{
      uint256 gasBegin = gasleft();
      address _impl = getUserWalletImplementation();
      require(_impl != address(0), "getUserWalletImplementation is 0");

      bytes memory ptr; 
      uint256 offset; 
      assembly {
        ptr := mload(0x40)
        calldatacopy(ptr, 0, calldatasize())
        let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
        let size := returndatasize()
        returndatacopy(ptr, 0, size)
        
        switch result
        case 0{
            if gt (size, 0) {
              offset := add(ptr, 0x120)
              mstore(0x40, offset)
              ptr := add(ptr, 4)
              let lengthFieldLength := mload(ptr)
              ptr := add(ptr, lengthFieldLength)
            }
        }
        default{
          return(ptr, size)
        }
      }

      (bool isSuccess, bytes memory data) = _impl.delegatecall(abi.encodeWithSignature("getGasFeeWalletAddress()"));
      if (!isSuccess){
        revert('Unable to call getGetFeeWalletAddress');
      }

      address gasFeeAddress = bytesToAddress(data);
      address payable gasFeeWallet = payable(gasFeeAddress);
      uint256 gasUsed = gasBegin - gasleft()  + extraGasFee;
      gasFeeWallet.transfer(gasUsed * tx.gasprice);

      emit SubmitWithdrawFailed(dest, gasUsed, withdrawAmount, amountWithFee, assetName, ptr);
      emit GasFeeTransferred(gasFeeWallet, gasUsed * tx.gasprice);    
  }


  fallback () external payable  {
    address _impl = getUserWalletImplementation();
    require(_impl != address(0), "getUserWalletImplementation is 0");

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

  receive() external payable {
    if(msg.value>0){
      emit DepositETH(msg.sender,msg.value);
    }
  }


  function  bytesToAddress(bytes memory b) private pure returns (address addr){
      assembly {
        addr := mload(add(b, 32))
      }
  }
}

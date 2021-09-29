pragma solidity >=0.6.0 <0.8.0;

import "./MultiSigWallet.sol";
import "../config/InternalSmartContractConfig.sol";
import "../withdraw/WithdrawSmartContract.sol";
import "../token/ITokenWithdrawable.sol";
import "./WalletAddressMap.sol";

contract ApprovalWalletStorage {

    uint[] public pendingTransList;
    InternalSmartContractConfig internalSCConfig;
    uint8 public queryPendingListCount; 
    address public fallbackAddr;
    uint public merchantId;

    string constant internal transActionKeyName = "transAction";
    string constant internal srcWalletKeyName = "srcWallet";
    string constant internal assetNameKeyName = "assetName";

    bytes32 constant internal transActionWithdrawHash = keccak256(abi.encodePacked("withdraw"));
    string constant internal transActionWithdraw = "withdraw";
    uint8 constant internal defaultQueryPendingListCount = 10;
}

contract ApprovalWallet is MultiSigWallet, ApprovalWalletStorage{
    
    event SubmitWithdraw(address indexed srcWallet, address indexed destWallet, address indexed submitterAddress, string assetName, uint transId, uint256 amount, uint256 feeAmount);
    event ApproveWithdraw(address indexed approverAddress, uint transId);

    constructor() MultiSigWallet(1) public   {
        queryPendingListCount = defaultQueryPendingListCount;
    }

    function init(address internalSCConfig, uint8 queryPendingListLimit) public onlyOwner{
      
        setInternalSmartContractConfig(internalSCConfig);
        queryPendingListCount = queryPendingListLimit;
    }

    function setInternalSmartContractConfig(address addr) public 
    onlyOwner{
        internalSCConfig = InternalSmartContractConfig(addr);
    }

    function setQueryPendingListCount(uint8 limitCount) public onlyOwner{
        queryPendingListCount = limitCount;
    }

    function setFallbackAddress(address addr) public onlyOwner{
        fallbackAddr = addr;
    }

    function getInternalSmartContractConfig() public onlyOwner view returns(address) {
        return address(internalSCConfig);
    }

    
    function submitWithdrawRequest(address srcWallet, address destWallet, uint256 amount, string memory assetName, uint256 feeAmount) public
        onlyWriter(_msgSender()) returns (uint)
    {

        uint transId = addTransaction(destWallet, amount, "");
        transactions[transId].isDirectInvokeData = false;
        miscellaneousData[transId][transActionKeyName] = string(transActionWithdraw);
        miscellaneousData[transId][srcWalletKeyName]= string(abi.encode(srcWallet));
        miscellaneousData[transId][assetNameKeyName] = assetName;


        submitCustomTransaction(transId);
        pendingTransList.push(transId);

        emit SubmitWithdraw(srcWallet, destWallet, _msgSender(), assetName, transId, amount, feeAmount);
        return transId;
    }

    function executeTransaction(uint transactionId) override internal
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];

            if (txn.isDirectInvokeData) {
               super.executeTransaction(transactionId);
            }else{
                string memory action = miscellaneousData[transactionId][transActionKeyName];
                if (keccak256(abi.encodePacked(action)) == transActionWithdrawHash){
                    //Withdraw
                    
                    WithdrawSmartContract withdrawSC = WithdrawSmartContract(payable(internalSCConfig.getWithdrawSmartContract()));
                    address srcWallet = abi.decode(bytes(miscellaneousData[transactionId][srcWalletKeyName]), (address));
                    string memory assetName = miscellaneousData[transactionId][assetNameKeyName];
                    withdrawSC.addWithdrawRequest(srcWallet, txn.destination, txn.value, assetName, address(this), transactionId);

                    emit ApproveWithdraw(msg.sender, transactionId);
                }
            }
            removePendingTransaction(txn.transId);
        }
    }

    function removePendingTransaction(uint transId) internal returns(bool){
        uint count = pendingTransList.length;
        for (uint i = 0; i < count; i++){
            if (pendingTransList[i] == transId){
                pendingTransList[i] = pendingTransList[count - 1];
                pendingTransList.pop();
                return true;
            }
        }
        return false;
    }

    //For ETH ONLY
    // function submitWithdraw(address dest, uint256 amount) public override{
        
    //     require(amount > 0, "Amount cannot be 0");

    //     address walletMapAddr = internalSCConfig.getWalletAddressMap();
    //     require(walletMapAddr != address(0), "WalletAddressMap is null");
    //     WalletAddressMap walletAddrMap = WalletAddressMap(internalSCConfig.getWalletAddressMap());
    //     bool isExist = walletAddrMap.isWalletAddressExist(msg.sender);
    //     require (isExist, "Wallet is not registered");
       
    //    bool isSenderMerchant = walletAddrMap.isMerchantWallet(msg.sender);
    //     if (merchantId == 0){
    //         require(!isSenderMerchant, "Sender is merchant");
    //     }else{
    //         require(isSenderMerchant, "Sender is not a merchant wallet");
    //         string memory str = walletAddrMap.getWalletInfoValue(msg.sender, "merchantId");
    //         require(bytes(str).length > 0, "Sender merchant Id not found");
    //         uint senderMerchantId = abi.decode(bytes(str), (uint));
    //         require (senderMerchantId == merchantId, "Sender is not for this approval wallet");
    //     }
        
    //     msg.sender.transfer(amount);

    //     submitWithdrawRequest(_msgSender(), dest, amount, "ETH");
    // }



  /**
  * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
  fallback () external payable  {

    require(fallbackAddr != address(0), "Fallback address is 0");

    address fAddr = fallbackAddr;

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize())
      let result := delegatecall(gas(), fAddr, ptr, calldatasize(), 0, 0)
      let size := returndatasize()
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
    // @return Binary format as following:
    //         
    //         Array of TransObject
    //         
    //         TransObject:
    //         transId uint256
    //         fromAddress address
    //         toAddress address
    //         assetName string
    //         amount uint256
    //         timestamp uint256
    //         
    // function getPendingTransactionList() public view returns(bytes memory){
    //     uint256 count = pendingTransList.length;

    //     if (count > queryPendingListCount){
    //         count = queryPendingListCount;
    //     }
    //     uint estimatedSize = estimationTransactionSize(uint8(count));
    //     uint offset = estimatedSize;
    //     bytes memory buffer = new bytes(estimatedSize);

    //     uintToBytes(offset, count, buffer);
    //     offset -=sizeOfUint(256);

    //     for (uint i = 0; i < count; i++){
    //         uint transId = pendingTransList[i];
    //         (buffer, offset) = serializeTransaction(transId, buffer, offset);
    //     }
    //     return buffer;
    // }

    // function estimationTransactionSize(uint8 count) internal pure returns(uint256){
    //     uint singleTransSize =   sizeOfUint(256) * 4 + sizeOfAddress() * 2 + sizeOfString("HELLO");
    //     return singleTransSize * count;
    // }

    // function serializeTransaction(uint transId, bytes memory buffer, uint startOffset) internal view returns(bytes memory, uint){

    //         uint offset = startOffset;

    //         Transaction storage trans = transactions[transId];

    //         uintToBytes(offset, transId, buffer);
    //         offset -= sizeOfUint(256);

    //         address strAddr = abi.decode(bytes(miscellaneousData[transId][srcWalletKeyName]), (address));
    //         addressToBytes(offset, strAddr, buffer);
    //         offset -= sizeOfAddress();
      
    //         addressToBytes(offset, trans.destination, buffer);
    //         offset -= sizeOfAddress();

    //         string memory assetName = miscellaneousData[transId][assetNameKeyName];
    //         stringToBytes(offset, bytes(assetName), buffer);
    //         offset -= sizeOfString(assetName);

    //         uintToBytes(offset, trans.value, buffer);
    //         offset -= sizeOfUint(256);

    //         uintToBytes(offset, trans.timestamp, buffer);
    //         offset -= sizeOfUint(256);

    //         return (buffer, offset);
    // }

    // function getTransactionDetails(uint transId) public view returns(bytes memory){
    //     uint256 estimatedSize = estimationTransactionSize(1);
    //     bytes memory buffer = new bytes(estimatedSize);
    //     uint offset = 0;
    //     (buffer, offset) =  serializeTransaction(transId, buffer, 0);
    //     return buffer;
    // }


    // function mergeBytes(bytes memory a, bytes memory b) public pure returns (bytes memory c) {
    //     // Store the length of the first array
    //     uint alen = a.length;
    //     // Store the length of BOTH arrays
    //     uint totallen = alen + b.length;
    //     // Count the loops required for array a (sets of 32 bytes)
    //     uint loopsa = (a.length + 31) / 32;
    //     // Count the loops required for array b (sets of 32 bytes)
    //     uint loopsb = (b.length + 31) / 32;
    //     assembly {
    //         let m := mload(0x40)
    //         // Load the length of both arrays to the head of the new bytes array
    //         mstore(m, totallen)
    //         // Add the contents of a to the array
    //         for {  let i := 0 } lt(i, loopsa) { i := add(1, i) } { mstore(add(m, mul(32, add(1, i))), mload(add(a, mul(32, add(1, i))))) }
    //         // Add the contents of b to the array
    //         for {  let i := 0 } lt(i, loopsb) { i := add(1, i) } { mstore(add(m, add(mul(32, add(1, i)), alen)), mload(add(b, mul(32, add(1, i))))) }
    //         mstore(0x40, add(m, add(32, totallen)))
    //         c := m
    //     }
    // }
}

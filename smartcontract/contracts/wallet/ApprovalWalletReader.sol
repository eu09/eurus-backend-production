pragma solidity >=0.6.0 <0.8.0;

import "./MultiSigWallet.sol";
import "./ApprovalWallet.sol";
import "../seriality/Seriality.sol";

contract ApprovalWalletReader is MultiSigWallet, ApprovalWalletStorage, Seriality{

    constructor() MultiSigWallet(2) public {
        queryPendingListCount = defaultQueryPendingListCount;
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
    function getPendingTransactionList() public view returns(bytes memory){
        uint256 count = pendingTransList.length;

        if (count > queryPendingListCount){
            count = queryPendingListCount;
        }
        uint estimatedSize = estimationTransactionSize(uint8(count));
        uint offset = estimatedSize;
        bytes memory buffer = new bytes(estimatedSize);

        uintToBytes(offset, count, buffer);
        offset -=sizeOfUint(256);

        for (uint i = 0; i < count; i++){
            uint transId = pendingTransList[i];
            (buffer, offset) = serializeTransaction(transId, buffer, offset);
        }
        return buffer;
    }

    function estimationTransactionSize(uint8 count) internal pure returns(uint256){
        uint singleTransSize =   sizeOfUint(256) * 4 + sizeOfAddress() * 2 + sizeOfString("HELLO");
        return singleTransSize * count;
    }

    function serializeTransaction(uint transId, bytes memory buffer, uint startOffset) internal view returns(bytes memory, uint){

            uint offset = startOffset;

            Transaction storage trans = transactions[transId];

            uintToBytes(offset, transId, buffer);
            offset -= sizeOfUint(256);

            address strAddr = abi.decode(bytes(miscellaneousData[transId][srcWalletKeyName]), (address));
            addressToBytes(offset, strAddr, buffer);
            offset -= sizeOfAddress();
      
            addressToBytes(offset, trans.destination, buffer);
            offset -= sizeOfAddress();

            string memory assetName = miscellaneousData[transId][assetNameKeyName];
            stringToBytes(offset, bytes(assetName), buffer);
            offset -= sizeOfString(assetName);

            uintToBytes(offset, trans.value, buffer);
            offset -= sizeOfUint(256);

            uintToBytes(offset, trans.timestamp, buffer);
            offset -= sizeOfUint(256);

            return (buffer, offset);
    }

    function getTransactionDetails(uint transId) public view returns(bytes memory){
        uint256 estimatedSize = estimationTransactionSize(1);
        bytes memory buffer = new bytes(estimatedSize);
        uint offset = 0;
        (buffer, offset) =  serializeTransaction(transId, buffer, 0);
        return buffer;
    }
}
pragma solidity >=0.6.0 <0.8.0;

import "../utils/ownable/ReadWritePermissionable.sol";
import "../config/EurusInternalConfig.sol";
contract EurusUserDeposit is ReadWritePermissionable {
    address payable public eurusPlatformWalletAddress;

    EurusInternalConfig public eurusInternalConfig;

    event Sweep(bytes32 indexed transactionHash, address indexed senderAddr, string assetName, uint256 amount);
    //event SweepFailure(bytes32 indexed transactionHash);

    constructor() public{}

    function setEurusInternalConfigAddress(address eurusInternalConfigAddr)public onlyOwner{
        eurusInternalConfig=EurusInternalConfig(eurusInternalConfigAddr);
    }

    function setEurusPlatformAddress(address eurusPlatformAddr)public onlyOwner{
        eurusPlatformWalletAddress=payable(eurusPlatformAddr);
    }

    function sweep(bytes32 transactionHash, address sender, string memory assetName, uint256 amount)public onlyWriter(msg.sender){
        require(sender!=address(0),"Invalid sender!");
        require(eurusPlatformWalletAddress!=(address(0)),"Platform Wallet Address hasn't been set!");
        if (keccak256(abi.encodePacked(assetName)) != keccak256(abi.encodePacked("ETH"))){
            address addr = eurusInternalConfig.getErc20SmartContractAddrByAssetName(assetName);
            require(addr!=address(0),"Invalid ERC20 assetName");
            bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", eurusPlatformWalletAddress, amount);
            (bool success, bytes memory returnData) = address(addr).call(data);
            require(success, string(returnData));
           //bool result;
           //bytes32 output;
           //(result, output) = external_call(addr,0,data);
           //require(result,  bytes32ToString(output));
        }else{
            eurusPlatformWalletAddress.transfer(amount);
        }
        emit Sweep(transactionHash,sender,assetName, amount);
    }

    //function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
    //    uint8 i = 0;
    //    while(i < 32 && _bytes32[i] != 0) {
    //        i++;
    //    }
    //    bytes memory bytesArray = new bytes(i);
    //    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
    //        bytesArray[i] = _bytes32[i];
    //    }
    //    return string(bytesArray);
    //}

   //function external_call(address destination, uint value, bytes memory data) internal returns (bool, bytes32) {
   //    bool result;
   //    bytes32 output;
   //    assembly {
   //        output := mload(0x40)
   //        result := call(
   //        gas(),
   //        destination,
   //        value,
   //        add(data, 32),     // First 32 bytes are the padded length of data, so exclude that
   //        mload(data),       // Size of the input (in bytes) - this is what fixes the padding problem
   //        output,
   //        0x40                  // Output is ignored, therefore the output size is zero
   //        )
   //    }
   //    return (result, output);
   //}

}


pragma solidity >=0.6.0 <0.8.0;
import "../utils/ownable/MultiOwnable.sol";
import "./ExternalSmartContractConfig.sol";
import "../utils/ownable/ReadWritePermissionable.sol";

contract InternalSmartContractConfig is ReadWritePermissionable{

    address mainnetWalletAddress; //Unused
    address innetWalletAddress; //Sidechain hot wallet
    address approvalWalletAddress; 
    address externalSCConfigAddress;
    address walletAddressMap;
    address withdrawSmartContract;
    address adminFeeWalletAddress; //Withdraw admin fee cold wallet
    address userWalletAddress; //User wallet logic smart contract address
    address gasFeeWalletAddress; //Gas fee for centralized user cold wallet
    address userWalletProxyAddress; //User wallet proxy for collecting EUN when transfer or withdraw failed
    address marketingRegWalletAddress; //Registration reward marketing wallet address

    constructor()public{}

    function setMainnetWalletAddress(address addr)public onlyOwner{
        mainnetWalletAddress = addr;
    }

    function setUserWalletAddress(address addr)public onlyOwner{
        userWalletAddress = addr;
    }

    function setInnetWalletAddress(address addr)public onlyOwner{
        innetWalletAddress=addr;
    }

    function setExternalSCConfigAddress(address addr)public onlyOwner{
        externalSCConfigAddress = addr;
    }

    function setAdminFeeWalletAddress(address addr)public onlyOwner{
        adminFeeWalletAddress = addr;
    }

    function setWalletAddressMap(address addr) public onlyOwner{
        walletAddressMap = addr;
    }

    function setApprovalWalletAddress(address addr) public onlyOwner{
        approvalWalletAddress = addr;
    }

    function setWithdrawSmartContract(address addr) public onlyOwner{
        withdrawSmartContract = addr;
    }

    function setUserWalletProxyAddress(address addr) public onlyOwner{
        userWalletProxyAddress = addr;
    }
    
    function setMarketingRegWalletAddress (address addr) public onlyOwner{
        marketingRegWalletAddress = addr;
    }

    function getInnetPlatformWalletAddress()public view returns (address){
        return innetWalletAddress;
    }

    function getMainnetPlatformWalletAddress()public view returns (address){
        return mainnetWalletAddress;
    }

    function getApprovalWalletAddress()public view returns (address){
        return approvalWalletAddress;
    }

    function getExternalSCConfigAddress() public view returns(address){
        return externalSCConfigAddress;
    }

    function getWalletAddressMap() public view returns(address){
        return walletAddressMap;
    }

    function getWithdrawSmartContract() public view returns(address){
        return withdrawSmartContract;
    }
    function getAdminFeeWalletAddress()public view returns (address){
        return adminFeeWalletAddress;
    }

    function getUserWalletAddress()public view returns (address){
        return userWalletAddress;
    }

    function getUserWalletProxyAddress() public view returns(address){
        return userWalletProxyAddress;
    }

    function getErc20SmartContractAddrByAssetName(string memory asset)public view returns(address) {
        ExternalSmartContractConfig exConfig = ExternalSmartContractConfig(externalSCConfigAddress);
        return exConfig.getErc20SmartContractAddrByAssetName(asset);
   }

   function setGasFeeWalletAddress(address addr) public onlyOwner {
       gasFeeWalletAddress = addr;
   }

   function getGasFeeWalletAddress() public view returns(address){
       return gasFeeWalletAddress;
   }

   function getMarketingRegWalletAddress() public view returns(address){
       return marketingRegWalletAddress;
   }

}
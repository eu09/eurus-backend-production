pragma solidity >=0.6.0 <0.8.0;
import "../utils/ownable/MultiOwnable.sol";
import "./ExternalSmartContractConfig.sol";

contract DummyInternalSmartContractConfig is MultiOwnable{

    address mainnetWalletAddress;
    address innetWalletAddress;
    address approvalWalletAddress;
    address externalSCConfigAddress;
    address walletAddressMap;
    address withdrawSmartContract;

    constructor()public{}

    function setMainnetWalletAddress(address addr)public onlyOwner{
        mainnetWalletAddress = addr;
    }

    function setInnetWalletAddress(address addr)public onlyOwner{
        innetWalletAddress=addr;
    }

    function setExternalSCConfigAddress(address addr)public onlyOwner{
        externalSCConfigAddress = addr;
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

    function getErc20SmartContractAddrByAssetName(string memory asset)public view returns(address) {
        ExternalSmartContractConfig exConfig = ExternalSmartContractConfig(externalSCConfigAddress);
        return exConfig.getErc20SmartContractAddrByAssetName(asset);
   }
}
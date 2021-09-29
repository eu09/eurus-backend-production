pragma solidity >=0.6.0 <0.8.0;
import "../utils/ownable/ReadWritePermissionable.sol";

contract WalletAddressMap is ReadWritePermissionable{
    /*
    struct WalletInfo{
        string email;
        bool isMerchant;
        bool isMetaMask;
        bool isExist;
    }
    */
    mapping(address=>mapping(string=>string)) walletInfoMap;
    address[] walletInfoList;
    mapping(address=>int256) lastUpdateTime;


    modifier isWalletNotExist(address inputAddress){
        require (bytes(walletInfoMap[inputAddress]["isExist"]).length == 0  , "WalletAddress: Wallet already exists");
        //require (walletInfoMap[inputAddress].isExist == false  , "WalletAddress: Wallet already exists");
        _;
    }

    modifier isWalletExist(address inputAddress){
        require (bytes(walletInfoMap[inputAddress]["isExist"]).length  > 0  , "WalletAddress: Wallet not exists");
        //require (walletInfoMap[inputAddress].isExist == false  , "WalletAddress: Wallet already exists");
        _;
    }

    constructor()public{}
    
    
    function setWalletInfo(address walletAddress, string memory key, string memory value) public isWalletExist(walletAddress) onlyOwnerOrWriter{
        require(keccak256(abi.encodePacked(walletInfoMap[walletAddress]["isExist"])) == keccak256(abi.encodePacked("true")), "Wallet address does not exists");

        walletInfoMap[walletAddress][key]=value;
    }


    function addWalletInfo(address walletAddress, string memory email, bool isMerchant, bool isMetaMask)public
        isWalletNotExist(walletAddress)
        onlyOwnerOrWriter{
        walletInfoMap[walletAddress]["email"]=email;
        walletInfoMap[walletAddress]["isMerchant"]=isMerchant?"true":"false";
        walletInfoMap[walletAddress]["isMetaMask"]=isMetaMask?"true":"false";
        walletInfoMap[walletAddress]["isExist"]="true";
        walletInfoMap[walletAddress]["kycLevel"]="0";
        walletInfoList.push(walletAddress);
    }
    
    function removeWalletInfo(address walletAddress) public onlyOwnerOrWriter isWalletExist(walletAddress) {
        walletInfoMap[walletAddress]["isExist"]="";
        walletInfoMap[walletAddress]["isMerchant"] = "";
        walletInfoMap[walletAddress]["isMetaMask"]="";
        walletInfoMap[walletAddress]["email"] = "";
        walletInfoMap[walletAddress]["kycLevel"]="";
        for (uint i=0; i<walletInfoList.length - 1; i++)
            if (walletInfoList[i] == walletAddress) {
                if (walletInfoList.length >= 1){
                    walletInfoList[i] = walletInfoList[walletInfoList.length - 1];
                }
                break;
            }
        walletInfoList.pop();
    }
    
    function isWalletAddressExist(address addr) public view returns(bool){
        return bytes(walletInfoMap[addr]["isExist"]).length > 0;
    }

    function isMerchantWallet(address addr) public view returns(bool){
        return keccak256(abi.encodePacked(walletInfoMap[addr]["isMerchant"])) == keccak256(abi.encodePacked("true"));
    }

    function getWalletInfoList()public view returns(address[] memory) {
        return walletInfoList;
    }
    
    function getWalletInfoValue(address addr, string memory field)public view returns(string memory) {
        return walletInfoMap[addr][field];
    }

    function getLastUpdateTime(address walletAddress)public view returns(int256){
        return lastUpdateTime[walletAddress];
    }

    function setLastUpdateTime(address walletAddress, int256 time)public isWalletExist(walletAddress) onlyOwnerOrWriter {
        lastUpdateTime[walletAddress] = time;
    }

}
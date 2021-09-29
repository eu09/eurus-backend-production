pragma solidity >=0.6.0 <0.8.0;

pragma experimental ABIEncoderV2;

import "../utils/ownable/MultiOwnable.sol";

contract EurusInternalConfig is MultiOwnable{
    struct Currency{
        address _currencyAddr;
        string assetName;
        bool isExist;
    }
    mapping(string=>Currency) currencySCMap;
    mapping(address=>string) currencyAddrMap;
    string[] currencyList;
    address[] public addressList;
    address public platformWalletAddress; //Hot wallet address
    address public eurusUserDepositAddress;

    modifier onlyNotAddedAddr(string memory assetName) {
        require(currencySCMap[assetName].isExist!=true, "Invalid to add an added address!");
        _;
    }

    modifier onlyAddedAddr(string memory assetName) {
        require(currencySCMap[assetName].isExist==true, "Invalid to del a non-existing asset!");
        _;
    }

    constructor()public{}

    function addCurrencyInfo(address _currencyAddr, string memory asset)public onlyOwner onlyNotAddedAddr(asset){
        currencySCMap[asset]=Currency(_currencyAddr,asset,true);
        currencyAddrMap[_currencyAddr]=asset;
        addressList.push(_currencyAddr);
        currencyList.push(asset);
    }
    
    function removeCurrencyInfo(string memory asset) public onlyOwner{
        currencyAddrMap[currencySCMap[asset]._currencyAddr]="";
        currencySCMap[asset].isExist=false;
        currencySCMap[asset]._currencyAddr = address(0);
        bool found = false;
        for (uint i=0; i<currencyList.length; i++)
            //Operator == not compatible with types string memory and string memory
            //compare strings by hashing the packed encoding values of the string
            if (keccak256(abi.encodePacked(currencyList[i])) == keccak256(abi.encodePacked(asset))) {
                if (currencyList.length >= 1){
                    currencyList[i] = currencyList[currencyList.length - 1];
                    addressList[i]=addressList[addressList.length - 1];
                }
                found = true;
            break;
            }
        if (found){
            currencyList.pop();
            addressList.pop();
        }
    }

    function getErc20SmartContractAddrByAssetName(string memory asset)public view returns(address) {
        return currencySCMap[asset]._currencyAddr;
    }

    function getErc20SmartContractByAddr(address _currencyAddr)public view returns(string memory){
        return currencyAddrMap[_currencyAddr];
    }

    function setPlatformWalletAddress(address coldWalletAddr)public onlyOwner{
        platformWalletAddress=coldWalletAddr;
    }

    function setEurusUserDepositAddress(address userDepositAddr) public onlyOwner{
        eurusUserDepositAddress=userDepositAddr;
    }

    function getAssetAddress()public view returns(string [] memory,  address [] memory){
        return (currencyList, addressList);
    }
}

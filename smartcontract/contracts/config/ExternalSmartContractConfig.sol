pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;
import "../utils/ownable/ReadWritePermissionable.sol";

contract ExternalSmartContractConfig is ReadWritePermissionable {
    struct Currency{
        address _currencyAddr;
        string assetName;
        bool isExist;
        uint decimal;
        string id;
    }
    mapping(string=>Currency) currencySCMap;
    mapping(address=>string) currencyAddrMap;
    mapping(string=>uint) currencyDecimalMap;
    mapping(string=>string) currencyIDMap;

    mapping(string=>uint) adminFeeMap;

    string[] public currencyList;
    address[] public addressList;

    mapping(string=>mapping(string=>uint256)) currencyKycLimit;

    modifier onlyNotAddedAddr(string memory assetName) {
        require(currencySCMap[assetName].isExist!=true, "Invalid to add an added asset!");
        _;
    }

    modifier onlyAddedAddr(string memory assetName) {
        require(currencySCMap[assetName].isExist==true, "Invalid to del a non-existing asset!");
        _;
    }

    function addCurrencyInfo(address _currencyAddr, string memory asset, uint decimal, string memory id)public onlyOwnerOrWriter onlyNotAddedAddr(asset){
        currencySCMap[asset]=Currency(_currencyAddr,asset,true,decimal,id);
        currencyAddrMap[_currencyAddr]=asset;
        currencyDecimalMap[asset] = decimal;
        currencyIDMap[asset] = id;
        currencyList.push(asset);
        addressList.push(_currencyAddr);
    }
    
    function removeCurrencyInfo(string memory asset) public onlyOwnerOrWriter{
        currencySCMap[asset].isExist=false;
        currencyAddrMap[currencySCMap[asset]._currencyAddr]="";
        currencySCMap[asset]._currencyAddr = address(0);
        currencyIDMap[asset] = "";
        currencyDecimalMap[asset] = 0;
        bool isFound = false;
        for (uint i=0; i<currencyList.length; i++)
            //Operator == not compatible with types string memory and string memory
            //compare strings by hashing the packed encoding values of the string
            if (keccak256(abi.encodePacked(currencyList[i])) == keccak256(abi.encodePacked(asset))) {
                if (currencyList.length >= 1){
                    currencyList[i] = currencyList[currencyList.length - 1];
                    addressList[i]=addressList[addressList.length - 1];
                }
                isFound = true;
                break;
            }
        if (isFound){
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

    function getAssetAddress()public view returns(string [] memory,  address [] memory){
        return (currencyList, addressList);
    }

    function getAssetDecimal(string memory asset) public view returns(uint) {
        return currencyDecimalMap[asset];
    }

    function getAssetListID(string memory asset) public view returns(string memory) {
        return currencyIDMap[asset];
    }

    function setETHFee(uint ethFee, string[] memory asset , uint[] memory amount) public onlyOwnerOrWriter{
        adminFeeMap["ETH"] = ethFee;
        for(uint i = 0;i < amount.length; i++) {
            setAdminFee(asset[i],amount[i]);
        }
    }

    function setAdminFee(string memory asset, uint amount) public onlyOwnerOrWriter {
        adminFeeMap[asset] = amount;
    }

    function getAdminFee(string memory asset) public view returns(uint){
        return adminFeeMap[asset];
    }

    function setKycLimit(string memory asset, string memory kycLevel, uint256 limit) public onlyOwnerOrWriter{
        currencyKycLimit[asset][kycLevel] = limit;
    }

    function getCurrencyKycLimit(string memory symbol, string memory kycLevel)public view returns(uint256){
        return currencyKycLimit[symbol][kycLevel];
    }

}

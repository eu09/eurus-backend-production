pragma solidity >=0.6.0 <0.8.0;

import "../utils/ownable/ReadWritePermissionable.sol";
import "../config/ExternalSmartContractConfig.sol";
import "../erc20/basic/ERC20.sol";

abstract contract DAppStockBase is ReadWritePermissionable{

    ExternalSmartContractConfig public config;
    
    event purchasedEvent(uint256 indexed productId,  address indexed buyer, uint256 quantity, string assetName, uint256 amount, bytes32 extraData);

    function purchase(address buyer, uint256 productId, uint256 quantity, string memory assetName, uint256 amount, bytes32 extraData) public{
        purchaseImpl(buyer, productId, quantity, assetName, amount, extraData);
        emit purchasedEvent(productId, buyer, quantity, assetName, amount, extraData);
    }

    function purchaseImpl(address buyer, uint256 productId, uint256 quantity, string memory assetName, uint256 amount, bytes32 extraData) internal virtual;

    function transfer(address dest, string memory assetName, uint256 amount) public onlyOwner{
        require( address(config) != address(0), "ExternalSmartContractConfig is not set");
        address assetAddress = config.getErc20SmartContractAddrByAssetName(assetName);
        require(assetAddress != address(0), "Invalid asset name");

        ERC20 erc20 = ERC20(assetAddress);
        erc20.transfer(dest, amount);
    }

    function setExternalSmartContractConfig(address configAddr) public onlyOwner{
        config = ExternalSmartContractConfig(configAddr);
    }

}
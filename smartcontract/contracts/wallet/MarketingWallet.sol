pragma solidity >=0.6.0 <0.8.0;

import "./MultiSigWallet.sol";
import "../config/InternalSmartContractConfig.sol";
import "../token/ITokenMintable.sol";
import "../erc20/basic/IERC20.sol";

contract MarketingWallet is MultiSigWallet{

    InternalSmartContractConfig internalSmartContractConfig;

    constructor() MultiSigWallet(2) public {
    }

    function setInternalSmartContractConfig(address addr) public 
    onlyOwner{
        internalSmartContractConfig = InternalSmartContractConfig(addr);
    }

    function getInternalSmartContractConfig() public onlyOwner view returns(address){
        return address(internalSmartContractConfig);
    }

    function transfer(address dest,string memory assetName, uint256 amount) internal onlyOwnerOrWalletOperator{
  
            address erc20Addr = internalSmartContractConfig.getErc20SmartContractAddrByAssetName(assetName);
            if(erc20Addr!=address(0)){
                IERC20 erc20 = IERC20(erc20Addr);
                erc20.transfer(dest, amount);
            }else{
                 revert("MarketingWallet: Invalid asset");
            }
       
    }

    function transferETH(address payable dest, uint256 amount) public payable onlyOwnerOrWalletOperator {
        dest.transfer(amount);
    }
}

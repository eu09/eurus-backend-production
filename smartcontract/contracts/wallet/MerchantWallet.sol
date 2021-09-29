pragma solidity >=0.6.0 <0.8.0;

import "./MultiSigWallet.sol";
import "../config/InternalSmartContractConfig.sol";

contract MerchantWallet is MultiSigWallet{
    InternalSmartContractConfig internal internalSmartContractContract;

    constructor(uint _required) MultiSigWallet(_required) public {
    }

    function setInternalSmartContract(address addr) public onlyOwner{
        internalSmartContractContract = InternalSmartContractConfig(addr);
    }

    function getInternalSmartContract() public onlyOwner view returns(address){
        return address(internalSmartContractContract);
    }

    function processPayment(string memory assetName, uint256 amount, string memory orderId, string memory txnId)public{

    }

    function transfer(address dest, string memory assetName, uint256 amount)public {

    }

    function withdraw(string memory assetName, uint256 amount)public{

    }

    function balanceOf(string memory assetName)public view{

    }

    function createPayment(string memory assetName, uint256 amount, string memory remarks, string memory orderId)public{

    }
}

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./MultiSigWallet.sol";
import "../config/InternalSmartContractConfig.sol";
import "../erc20/basic/ERC20.sol";
import "../erc20/extend/EurusERC20.sol";
import "./IUserWallet.sol";


contract UserWallet is MultiSigWallet, IUserWallet{
    uint[] public TranList;
    InternalSmartContractConfig internalSmartContractContract;

    event TransferRequestEvent(uint256 indexed transactionId,  address indexed dest, uint256 indexed gasUsedByUser, string assetName,  uint256 amount);
    event WithdrawRequestEvent(address indexed dest, uint256 indexed gasUsedByUser, uint256 indexed withdrawAmount,  string assetName, uint256 amountWithFee);
    event TransferEvent(uint256 indexed transactionId,  address indexed dest, string assetName, uint256 indexed amount);
    

    string constant internal assetNameKeyName = "assetName";
    string constant internal destAddressKeyName = "destAddress";
    uint256 constant internal gasFeeAdjustment = 49000;

    constructor() MultiSigWallet(2) public {
    }

    function setInternalSmartContractConfig(address addr) public 
    onlyOwner{
        internalSmartContractContract = InternalSmartContractConfig(addr);
    }

    function directRequestTransfer(address dest,string memory assetName, uint256 amount) public isWalletOwner(_msgSender()){
        uint256 gasBegin = gasleft();
        address tmp ;
        bool isEun = false;
        if (keccak256(abi.encodePacked("EUN")) == keccak256(abi.encodePacked(assetName))){
            isEun = true;
        }
        if (!isEun) {
            tmp = internalSmartContractContract.getErc20SmartContractAddrByAssetName(assetName);
        }

        if(tmp!=address(0) || isEun ){
            uint transId = addTransaction(dest, amount, "");
            transactions[transId].isDirectInvokeData = false;
            miscellaneousData[transId][assetNameKeyName] = assetName;
            miscellaneousData[transId][destAddressKeyName] = string(abi.encode(dest));
            submitCustomTransaction(transId);
            TranList.push(transId);
            uint256 gasEnd = gasleft();
            uint256 gasUsed = gasEnd - gasBegin;
            emit TransferRequestEvent(transId, dest, gasUsed, assetName, amount);
    
        }else{
            revert("Invalid asset!");
        }
    }

    function requestTransfer(address dest, string memory assetName, uint256 amount, bytes memory signature) public override onlyWriter(_msgSender()){
       uint256 gasBegin = gasleft();
       bytes32 hash = keccak256(abi.encode(dest, assetName, amount));
       address senderAddr = verifySignature(hash, signature);
       require(senderAddr == walletOwner , 'Sender is not wallet owner');

        address tmp ;
        bool isEun = false;
        if (keccak256(abi.encodePacked("EUN")) == keccak256(abi.encodePacked(assetName))){
            isEun = true;
        }

        if (!isEun) {
            tmp = internalSmartContractContract.getErc20SmartContractAddrByAssetName(assetName);
        }
        address payable gasFeeCollectorAddress = address(0);

        uint transId;

        if(tmp!=address(0) || isEun ){
            transId = addTransaction(dest, amount, "");
            transactions[transId].isDirectInvokeData = false;  
            miscellaneousData[transId][assetNameKeyName] = assetName;
            miscellaneousData[transId][destAddressKeyName] = string(abi.encode(dest));
            
            confirmations[transId][walletOwner] = true;
            Confirmation(walletOwner, transId);
            if (required == 1){
                executeTransaction(transId);
            }
            TranList.push(transId);
            gasFeeCollectorAddress = payable(internalSmartContractContract.getGasFeeWalletAddress());
            

        }else{
            revert("Invalid asset!");
        }

        require(gasFeeCollectorAddress != address(0), 'Gas fee wallet address is 0');
        uint256 gasUsed = gasBegin - gasleft() + gasFeeAdjustment;
        gasFeeCollectorAddress.transfer(gasUsed * tx.gasprice);
        emit TransferRequestEvent(transId, dest, gasUsed, assetName, amount);
        emit GasFeeTransferred(gasFeeCollectorAddress, gasUsed* tx.gasprice);
    }

    function getGasFeeWalletAddress() public view returns(address){
        return internalSmartContractContract.getGasFeeWalletAddress();
    }

    function verifySignature(bytes32 hash, bytes memory signature) public pure returns (address) {
        address addressFromSig = recoverSigner(hash, signature);
        return addressFromSig;
    }
//
//    /**
//    * @dev Recover signer address from a message by using their signature
//    * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
//    * @param sig bytes signature, the signature is generated using web3.eth.sign(). Inclusive "0x..."
//    */
    function recoverSigner(bytes32 hash, bytes memory sig) private pure returns (address) {
        require(sig.length == 65, "Require correct length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Signature version not match");

        return recoverSigner2(hash, v, r, s);
    }

    function recoverSigner2(bytes32 h, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        address addr = ecrecover(h, v, r, s);
        return addr;
    }


    function transfer(uint256 transId, address dest,string memory assetName, uint256 amount) internal{

        if (keccak256(abi.encodePacked("EUN")) == keccak256(abi.encodePacked(assetName))){
            payable(dest).transfer(amount);
        }else{
            address erc20Addr = internalSmartContractContract.getErc20SmartContractAddrByAssetName(assetName);
            if(erc20Addr!=address(0)){
                ERC20 erc20 = ERC20(erc20Addr);
                erc20.transfer(dest, amount);
            }else{
                revert("Invalid asset!");
            }
        }

        emit TransferEvent(transId, dest, assetName, amount);
    }

    function executeTransaction(uint transId) override internal
    confirmed(transId, msg.sender)
    {
        Transaction storage txn = transactions[transId];
        require (!txn.executed, "Transaction already executed");

        if (isConfirmed(transId)) {
            txn.executed = true;
            string memory assetName = miscellaneousData[transId][assetNameKeyName];
            address dest = abi.decode(bytes(miscellaneousData[transId][destAddressKeyName]), (address));

            transfer(transId, dest, assetName, txn.value);
        }
    }

    function directSubmitWithdraw(address dest, uint256 withdrawAmount, uint256 amountWithFee, string memory assetName) public onlyWalletOperator {

        require (keccak256(abi.encodePacked("EUN")) != keccak256(abi.encodePacked(assetName)), 'EUN is not eligible to withdraw');
        address addr = internalSmartContractContract.getErc20SmartContractAddrByAssetName(assetName);
        require(addr != address(0), 'Asset not found');
        EurusERC20(addr).submitWithdraw(dest, withdrawAmount, amountWithFee);
        
    }

    function submitWithdraw(address dest, uint256 withdrawAmount, uint256 amountWithFee, string memory assetName, bytes memory signature) public override onlyWriter(_msgSender()) {

        uint256 gasBegin = gasleft();
        require (keccak256(abi.encodePacked("EUN")) != keccak256(abi.encodePacked(assetName)), 'EUN is not eligible to withdraw');
        bytes32 hash = keccak256(abi.encode(dest, withdrawAmount, amountWithFee, assetName));
        address senderAddr = verifySignature(hash, signature);
        require(senderAddr == walletOwner , 'Sender is not wallet owner');

        address addr = internalSmartContractContract.getErc20SmartContractAddrByAssetName(assetName);
        require(addr != address(0), 'Asset not found');
        EurusERC20(addr).submitWithdraw(dest, withdrawAmount, amountWithFee);
        
        address payable gasFeeCollectorAddress = payable(internalSmartContractContract.getGasFeeWalletAddress());
        require(gasFeeCollectorAddress != address(0), 'Gas fee wallet address is 0');
        
        uint256 gasUsed = gasBegin - gasleft() + gasFeeAdjustment;
        gasFeeCollectorAddress.transfer(gasUsed * tx.gasprice);

        emit WithdrawRequestEvent(dest, gasUsed, withdrawAmount, assetName, amountWithFee);
        emit GasFeeTransferred(gasFeeCollectorAddress, gasUsed* tx.gasprice);
    }


}
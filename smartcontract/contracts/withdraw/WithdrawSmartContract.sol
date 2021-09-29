pragma solidity >=0.6.0 <0.8.0;
import "../wallet/MultiSigWallet.sol";
import "../config/InternalSmartContractConfig.sol";
import "../token/ITokenWithdrawable.sol";

contract WithdrawSmartContract is MultiSigWallet {

    InternalSmartContractConfig public internalSCConfig;
    string constant internal srcWalletKeyName = "srcWallet";
    string constant internal assetNameKeyName = "assetName";
    string constant internal burnWalletKeyName = "burnWallet";
    string constant internal approvalWalletKeyName = "approvalWallet";
    string constant internal approvalTransIdKeyName = "requestTransId";

    event WithdrawEvent(address indexed approvalWallet, uint256 indexed requestTransId, address srcWallet, address destWallet, string assetName, uint transId, uint256 amount);
    event BurnCompletedEvent(address indexed approvalWallet, uint256 indexed requestTransId, uint transId);
    constructor() public 
    MultiSigWallet(5){
    }

    function init(address internalSCConfigAddr, uint requiredCount) public onlyOwner{
        internalSCConfig = InternalSmartContractConfig(internalSCConfigAddr);
        required = requiredCount;
    }

    function addWithdrawRequest(address srcWallet, address destWallet, uint256 amount, 
    string memory assetName, address approvalWallet, uint256 requestTransId) public onlyWriter(_msgSender()) {

        uint transId = addTransaction(destWallet, amount, "");
        transactions[transId].isDirectInvokeData = false;
        miscellaneousData[transId][assetNameKeyName] = assetName;
        miscellaneousData[transId][srcWalletKeyName] = string(abi.encode(srcWallet));
        miscellaneousData[transId][burnWalletKeyName] = string(abi.encode(msg.sender));
        miscellaneousData[transId][approvalWalletKeyName] = string(abi.encode(approvalWallet));
        miscellaneousData[transId][approvalTransIdKeyName] = string(abi.encode(requestTransId));

        submitCustomTransaction(transId);

        emit WithdrawEvent(approvalWallet, requestTransId, srcWallet, destWallet, assetName, transId, amount);
        
    }

    function executeTransaction(uint transId) override internal
        confirmed(transId, msg.sender)
        //notExecuted(transId)
    {
        Transaction storage txn = transactions[transId];
        require (!txn.executed, "Transaction already executed");

        if (isConfirmed(transId)) {
            txn.executed = true;
            string memory assetName = miscellaneousData[transId][assetNameKeyName];
            address assetSC = internalSCConfig.getErc20SmartContractAddrByAssetName(assetName);
            require (assetSC != address(0), 'Asset address not found');

            ITokenWithdrawable withdrawable = ITokenWithdrawable(payable(assetSC));
            require (address(withdrawable) != address(0), 'Asset address cannot cast to ITokenWithdrawable');

            address approvalWallet = abi.decode(bytes(miscellaneousData[transId][approvalWalletKeyName]), (address));

            withdrawable.burn(approvalWallet, transactions[transId].value);
            uint256 approvalTransId = abi.decode(bytes(miscellaneousData[transId][approvalTransIdKeyName]) , (uint256));

            emit BurnCompletedEvent(approvalWallet, approvalTransId, transId);
        }
    }

}

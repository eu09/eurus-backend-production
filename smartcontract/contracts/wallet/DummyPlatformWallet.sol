pragma solidity >=0.6.0 <0.8.0;

import "./MultiSigWallet.sol";
import "../config/InternalSmartContractConfig.sol";
import "../token/ITokenMintable.sol";
import "../erc20/basic/IERC20.sol";

contract DummyPlatformWallet is MultiSigWallet{
    InternalSmartContractConfig internalSmartContractConfig;

    event MintRequestEvent(uint256 indexed mintRequestTransId, string mainnetDepositTransHash);
    event MintCompletedEvent(uint256 indexed mintRequestTransId, string mainnetDepositTransHash);

    string internal constant mainnetTransHashKeyName = "mainnetTransHash";
    string internal constant transActionKeyName = "action";
    string internal constant transAssetNameKeyName = "assetName";

    bytes32 internal constant transActionHash =  keccak256(abi.encodePacked("deposit"));
    string internal constant transAction = "deposit";
    
    
    constructor() MultiSigWallet(2) public {
    }

    // modifier onlyOwnerOrWalletOperator() {
    //     require(isOwner(msg.sender) || walletOperatorMap[msg.sender] == true || walletOwner == msg.sender, 
    //     "PlatformWallet: caller is not one of the owner or wallet operator");
    //     _;
    // }


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
                 revert("PlatformWallet: Invalid asset");
            }
       
    }

    function submitMintRequest(address dest, string memory assetName, uint256 amount, string memory mainnetTransHash) public onlyWalletOperator returns (uint transactionId){
            require(address(internalSmartContractConfig) != address(0));
            address erc20Addr = internalSmartContractConfig.getErc20SmartContractAddrByAssetName(assetName);
            if(erc20Addr!=address(0)){
                
                uint256 mintRequestTransId = addTransaction(dest, amount, "");
                transactionId = mintRequestTransId;
                transactions[mintRequestTransId].isDirectInvokeData = false;
                miscellaneousData[mintRequestTransId][mainnetTransHashKeyName] = mainnetTransHash;
                miscellaneousData[mintRequestTransId][transActionKeyName] = transAction;
                miscellaneousData[mintRequestTransId][transAssetNameKeyName] = assetName;
                submitCustomTransaction(mintRequestTransId);
                 emit MintRequestEvent(mintRequestTransId, mainnetTransHash);

            }else{
                revert("PlatformWallet: Invalid asset!");
            }
    }

    function executeTransaction(uint transactionId) override internal
        confirmed(transactionId, msg.sender)
        //notExecuted(transactionId)
    {
        Transaction storage txn = transactions[transactionId];
        require (!txn.executed, "Transaction already executed");
        if (isConfirmed(transactionId)) {

            string memory action = miscellaneousData[transactionId][transActionKeyName];
            if (keccak256(abi.encodePacked(action)) == transActionHash) {
                txn.executed = true;
                string memory assetName = miscellaneousData[transactionId][transAssetNameKeyName];
                mint(txn.destination, assetName, txn.value);
                string memory depositTransHash = miscellaneousData[transactionId][mainnetTransHashKeyName];
 
                emit MintCompletedEvent(transactionId, depositTransHash);
               
            }
            // else{
            //     revert("Invalid action");
            // }
            
        }
    }


    function mint(address dest, string memory assetName, uint256 amount)internal onlyOwnerOrWalletOperator{
        address erc20Addr = internalSmartContractConfig.getErc20SmartContractAddrByAssetName(assetName);
        if(erc20Addr!=address(0)){
            ITokenMintable tokenMintable = ITokenMintable(erc20Addr);
            tokenMintable.mint(address(this), amount);
           
            IERC20 erc20 = IERC20(erc20Addr);
            erc20.transfer(dest, amount);


        }else{
            revert("PlatformWallet: asset name not found");
        }
    }

    function transferETH(address payable dest, uint256 amount) public onlyOwnerOrWalletOperator{
        require(address(this).balance>amount,"Platform Wallet has insufficient amount");
        dest.transfer(amount);
    }
}
pragma solidity >=0.6.0 <0.8.0;

import "./TxMultiSigWallet.sol";
import "../config/InternalSmartContractConfig.sol";
import "../token/ITokenMintable.sol";
import "../erc20/basic/IERC20.sol";

contract PlatformWallet is TxMultiSigWallet{
    InternalSmartContractConfig internalSmartContractConfig;

    event MintRequestEvent(bytes32 indexed mintRequestTransId);
    event MintCompletedEvent(bytes32 indexed mintRequestTransId);

    string internal constant transActionKeyName = "action";
    string internal constant transAssetNameKeyName = "assetName";

    bytes32 internal constant transActionHash =  keccak256(abi.encodePacked("deposit"));
    string internal constant transAction = "deposit";
    
    
    constructor() TxMultiSigWallet(5) public {
    }

    modifier onlyOwnerOrWalletOperator() {
        require(isOwner(msg.sender) || walletOperatorMap[msg.sender] == true || walletOwner == msg.sender, 
        "PlatformWallet: caller is not one of the owner or wallet operator");
        _;
    }


    function setInternalSmartContractConfig(address addr) public 
    onlyOwner{
        internalSmartContractConfig = InternalSmartContractConfig(addr);
    }

    function getInternalSmartContractConfig() public view returns(address){
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

    function submitMintRequest(address dest, string memory assetName, uint256 amount, bytes32 mainnetTransHash) public onlyWalletOperator {
            require(address(internalSmartContractConfig) != address(0));
            address erc20Addr = internalSmartContractConfig.getErc20SmartContractAddrByAssetName(assetName);
            if(erc20Addr!=address(0)){
                
                addTransaction(mainnetTransHash, dest, amount, "");
              
                transactions[mainnetTransHash].isDirectInvokeData = false;
                miscellaneousData[mainnetTransHash][transActionKeyName] = transAction;
                miscellaneousData[mainnetTransHash][transAssetNameKeyName] = assetName;
                submitCustomTransaction(mainnetTransHash);
                emit MintRequestEvent(mainnetTransHash);

            }else{
                revert("PlatformWallet: Invalid asset!");
            }
    }

    function executeTransaction(bytes32 transactionId) override internal
        confirmed(transactionId, msg.sender)
    {
        Transaction storage txn = transactions[transactionId];
        require (!txn.executed, "Transaction already executed");
        if (isConfirmed(transactionId)) {

            string memory action = miscellaneousData[transactionId][transActionKeyName];
            if (keccak256(abi.encodePacked(action)) == transActionHash) {
                txn.executed = true;
                string memory assetName = miscellaneousData[transactionId][transAssetNameKeyName];
                mint(txn.destination, assetName, txn.value);
    
                emit MintCompletedEvent(transactionId);
            }
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

    function transferETH(address payable dest, uint256 amount) public payable onlyOwnerOrWalletOperator {
        //require(address(this).balance>amount,"Platform Wallet has insufficient amount");
        dest.transfer(amount);
    }
}
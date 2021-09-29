pragma solidity >=0.6.0 <0.8.0;

import "../basic/ERC20.sol";
import "../../config/InternalSmartContractConfig.sol";
import "../../wallet/ApprovalWallet.sol";
import "../../wallet/WalletAddressMap.sol";
import "../../token/ITokenWithdrawable.sol";
import "../../token/ITokenMintable.sol";
import "../../config/ExternalSmartContractConfig.sol";
import "../../dapp/DAppBase.sol";
import "../../dapp/DAppStockBase.sol";


contract EurusERC20 is ERC20, ITokenWithdrawable, ITokenMintable {

    InternalSmartContractConfig internal internalSCConfig;
    ExternalSmartContractConfig internal externalSCConfig;
    
    address[] public blackListDestAddress;
    mapping(address => bool) public blackListDestAddressMap;

    mapping(address=>uint256) public dailyWithdrewAmount;

    event DepositedToDApp(address indexed buyer, address indexed dappAddress, uint256 indexed amount, string symbol, bytes32 extraData);

    modifier onlyNonBlackListDestAddress(address destAddr){
        require(!blackListDestAddressMap[destAddr], "Blacklist dest address");
        _;
    }

        modifier onlyBlackListDestAddress(address destAddr){
        require(blackListDestAddressMap[destAddr], "Blacklist dest address not found");
        _;
    }


    function init(address internalSCAddr, string memory name_, string memory symbol_, uint256 totalSupply_, uint8 decimals_, address externalSCAddr) public onlyOwner {
        super.init(name_, symbol_, totalSupply_, decimals_);
        internalSCConfig = InternalSmartContractConfig(internalSCAddr);
        externalSCConfig = ExternalSmartContractConfig(externalSCAddr);
    }

    function mint(address account, uint256 amount) public onlyOwnerOrWriter override{
    _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwnerOrWriter override {
    _burn(account, amount);
    }

    function submitWithdraw(address dest, uint256 withdrawAmount, uint256 amountWithFee) public onlyNonBlackListDestAddress(dest) override {
        require (amountWithFee > withdrawAmount, "Total amount smaller than amount");
        uint256 feeAmount = amountWithFee - withdrawAmount;

        address walletMapAddr = internalSCConfig.getWalletAddressMap();
        require(walletMapAddr != address(0), "WalletAddressMap is null");
        WalletAddressMap walletAddrMap = WalletAddressMap(internalSCConfig.getWalletAddressMap());
        bool isExist = walletAddrMap.isWalletAddressExist(_msgSender());
        require (isExist, "Wallet is not registered");


        if (int(block.timestamp)/int(86400)*int(86400)==int(walletAddrMap.getLastUpdateTime(_msgSender()))/int(86400)*int(86400)){
            require(externalSCConfig.getCurrencyKycLimit(symbol(),walletAddrMap.getWalletInfoValue(_msgSender(), "kycLevel"))>=dailyWithdrewAmount[_msgSender()]+withdrawAmount, "exceed daily withdraw amount");
            dailyWithdrewAmount[_msgSender()] = dailyWithdrewAmount[_msgSender()]+withdrawAmount;
        }else{
            require(externalSCConfig.getCurrencyKycLimit(symbol(),walletAddrMap.getWalletInfoValue(_msgSender(), "kycLevel"))>=withdrawAmount, "exceed daily withdraw amount");
            dailyWithdrewAmount[_msgSender()] = withdrawAmount;
        }
        walletAddrMap.setLastUpdateTime(_msgSender(), int256(block.timestamp));


        address adminFeeWalletAddr =  internalSCConfig.getAdminFeeWalletAddress();
        bool adminFeeIsSuccess = transfer(adminFeeWalletAddr, feeAmount);
        require (adminFeeIsSuccess, "Transfer to AdminFee Wallet failed");

        address approvalWalletAddr =  internalSCConfig.getApprovalWalletAddress();
        bool isSuccess = transfer(approvalWalletAddr, withdrawAmount);
        require (isSuccess, "Transfer to Approval Wallet failed");
        ApprovalWallet approvalWallet = ApprovalWallet(payable(approvalWalletAddr));
        approvalWallet.submitWithdrawRequest(_msgSender(), dest, withdrawAmount, symbol(),feeAmount);
    }

    function depositToDApp(uint256 amount, address dappAddress, bytes32 extraData) public{
        transfer(dappAddress, amount);
        DAppBase dapp = DAppBase(dappAddress);
        dapp.mintCustomToken(symbol(), amount, _msgSender(), extraData);

        emit DepositedToDApp(_msgSender(), dappAddress, amount, symbol(), extraData);
    }

    function purchase(uint256 productId, uint256 quantity, uint256 amount, address dappAddress, bytes32 extraData) public{
        transfer(dappAddress, amount);
        DAppStockBase stock =  DAppStockBase(dappAddress);
        stock.purchase(_msgSender(), productId, quantity, symbol(), amount, extraData);
    }

    function setInternalSCConfigAddress(address addr) public 
        onlyOwner{
            internalSCConfig = InternalSmartContractConfig(addr);
            
    }

    function getInternalSCConfigAddress() public view returns(address){
        return address(internalSCConfig);
    }

    function addBlackListDestAddress(address addr) public onlyOwner onlyNonBlackListDestAddress(addr) {
        blackListDestAddressMap[addr] = true;
        blackListDestAddress.push(addr);
    }

    function removeBlackListDestAddress(address addr) public onlyOwner onlyBlackListDestAddress(addr) {

        uint256 len = blackListDestAddress.length;
        for (uint256 i = 0 ; i < len; i++){
            if (blackListDestAddress[i] == addr){
                blackListDestAddress[i] = blackListDestAddress[len - 1] ;
                break;
            }
        }
        blackListDestAddress.pop();
        blackListDestAddressMap[addr] = false;
    }

 /**
   * @notice Recover the signer of hash, assuming it's an EOA account
   * @dev Only for EthSign signatures
   * @param _hash       Hash of message that was signed
   * @param _signature  Signature encoded as (bytes32 r, bytes32 s, uint8 v)
   */
  function recoverSigner(
    bytes32 _hash,
    bytes memory _signature
  ) internal pure returns (address signer) {
    require(_signature.length == 66, "SignatureValidator#recoverSigner: invalid signature length");

    // Variables are not scoped in Solidity.
    // uint8 v = uint8(_signature[64]);
    // bytes32 r = _signature.readBytes32(0);
    // bytes32 s = _signature.readBytes32(32);

    uint8 v;
    bytes32 r;
    bytes32 s;
    assembly{
        r := mload(_signature)
        s:= mload(add(_signature, 32))
        v := byte(0, mload(add(_signature, 64)))
    }


    // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
    // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
    // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
    // signatures from current libraries generate a unique signature with an s-value in the lower half order.
    //
    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
    // these malleable signatures as well.
    //
    // Source OpenZeppelin
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol

    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
      revert("SignatureValidator#recoverSigner: invalid signature 's' value");
    }

    if (v != 27 && v != 28) {
      revert("SignatureValidator#recoverSigner: invalid signature 'v' value");
    }

    // Recover ECDSA signer
    signer = ecrecover(
      keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)),
      v,
      r,
      s
    );
    
    // Prevent signer from being 0x0
    require(
      signer != address(0x0),
      "SignatureValidator#recoverSigner: INVALID_SIGNER"
    );

    return signer;
  }

}
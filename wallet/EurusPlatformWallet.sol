pragma solidity >=0.6.0 <0.8.0;

pragma experimental ABIEncoderV2;
import "../utils/ownable/ReadWritePermissionable.sol";
import "../erc20/basic/ERC20.sol";
import "../config/EurusInternalConfig.sol";
import "../utils/maths/SafeMath.sol";
import "../utils/basic/Address.sol";
import "../erc20/extend/SafeERC20.sol";

contract EurusPlatformWallet is ReadWritePermissionable{
    using SafeMath for uint256;
    using Address for address;
    using Address for address payable;
    using SafeERC20 for ERC20;

    bytes32 constant internal ethNameHash = keccak256(abi.encodePacked("ETH"));
    EurusInternalConfig internal internalConfig;
    mapping (address => bool) private withdrawIDMap;
    mapping (bytes32 => bool) private processedTransHash;

    uint public requireSig = 5;

    modifier onlyWriterOrOwner(){
        require(writerMap[msg.sender] ||  isOwner(msg.sender), "EurusPlatformWallet: Writer or owner only");
        _;
    }

    function setEurusInternalConfig(address addr) public onlyOwner{
        require(addr.isContract(), 'Input address is not a smart contract address');
        internalConfig = EurusInternalConfig(addr);
    }

    function getEurusInternalConfig() public view returns (address) {
        return address(internalConfig);
    }

    function transfer(bytes32 requestTransHash, address toAddr, string memory assetName, uint256 amount, uint8 decimal, bytes[] memory signature) public onlyWriterOrOwner {
        require(processedTransHash[requestTransHash] != true, 'EurusPlatformWallet: Duplicated transaction');
        processedTransHash[requestTransHash] = true;

        bytes32 hash = keccak256(abi.encode(requestTransHash, toAddr, assetName, amount));
        verify(hash, signature);
        if (keccak256(abi.encodePacked(assetName)) != ethNameHash){
            address erc20Addr = internalConfig.getErc20SmartContractAddrByAssetName(assetName);
            require(erc20Addr != address(0), "EurusPlatformWallet: Asset name not found");
            ERC20 erc20 = ERC20(erc20Addr);

            uint8 targetDecimal = erc20.decimals();
            if (targetDecimal == decimal ){
                erc20.safeTransfer(toAddr, amount);
            }else if (targetDecimal > decimal){
                uint8 delta = targetDecimal - decimal;
                require(delta <= 30, 'Target decimal point different cannot larger than 30');
                uint256 targetAmount =  amount.mul(uint256(10) ** delta);
                erc20.safeTransfer(toAddr, targetAmount);
            }else {
                uint256 delta =  decimal - targetDecimal;
                require(delta <= 30, 'Side chain decimal point different cannot larger than 30');
                uint256 targetAmount = amount.div(uint256(10) ** delta);
                erc20.safeTransfer(toAddr, targetAmount);
            }
        }else {
            payable(toAddr).sendValue(amount);
        }
    }

    function verify (bytes32 hash, bytes[] memory signature) public returns(bool) {
        address[5] memory signedData;
        for(uint i = 0;i<requireSig;i++){
            address signatureAddr = verifySignature(hash, signature[i]);
            require (signatureAddr != address(0), 'EurusPlatformWallet: signature sender is not a writer');
            require (withdrawIDMap[signatureAddr]!=true, 'EurusPlatformWallet: duplicate signature address');
            withdrawIDMap[signatureAddr]=true;
            signedData[i]=signatureAddr;
        }

        for(uint i = 0;i<requireSig;i++){
            withdrawIDMap[signedData[i]]=false;
        }
        return true;
    }

    function verifySignature(bytes32 hash, bytes memory signature) public view returns (address) {
        address addressFromSig = recoverSigner(hash, signature);
        if(isWriter(addressFromSig)){
            return addressFromSig;
        }
        return address(0);
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

}
pragma solidity >=0.6.0 <0.8.0;

import "../token/ITokenMintable.sol";
import "../erc20/basic/ERC20.sol";
import "../config/ExternalSmartContractConfig.sol";

abstract contract DAppBase is ERC20 {

    ExternalSmartContractConfig public config;
    event refunded (address indexed dest, uint256 indexed srcAmount, uint256 indexed targetAmount, string srcAssetName, string targetAssetName, bytes32 extraData);

    function mintCustomToken(string memory receivedTokenSymbol, uint256 amount, address dest, bytes32 extraData) public virtual;

    function refund(string memory targetAssetName, uint256 srcAmount, address dest, bytes32 extraData) public virtual;

    function safeRefund(string memory targetAssetName, uint256 srcAmount, uint256 refundAmount, address dest, bytes32 extraData) internal virtual{
        address addr =  config.getErc20SmartContractAddrByAssetName(targetAssetName);
        require(addr != address(0), "Asset not found");

        ERC20 erc20 = ERC20(addr);
        erc20.transfer(dest, refundAmount);
        emit refunded(dest, srcAmount, refundAmount, symbol(), targetAssetName, extraData);
    }

    function setExternalSmartContractConfig(address extAddr) public onlyOwner{
        config = ExternalSmartContractConfig(extAddr);
    }
}
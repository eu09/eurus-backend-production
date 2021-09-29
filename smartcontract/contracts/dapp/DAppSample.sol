pragma solidity >=0.6.0 <0.8.0;

import "./DAppBase.sol";


contract DAppSample is DAppBase {

   function mintCustomToken(string memory receivedTokenSymbol, uint256 amount, address dest, bytes32 extraData) public override onlyOwnerOrWriter{
       _mint(dest, amount);
    }

    function refund(string memory targetAssetName, uint256 srcAmount, address dest, bytes32 extraData) public override onlyOwner{
        _burn(dest, srcAmount);
        safeRefund(targetAssetName, srcAmount, srcAmount, dest, extraData);

    }

}

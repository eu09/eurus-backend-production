pragma solidity >=0.6.0 <0.8.0;

import "../basic/ERC20.sol";
import "../../config/InternalSmartContractConfig.sol";
import "../../wallet/ApprovalWallet.sol";
import "../../wallet/WalletAddressMap.sol";
import "../../token/ITokenMintable.sol";

contract TestERC20 is ERC20, ITokenMintable {

    function mint(address account, uint256 amount) public onlyOwnerOrWriter override{
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwnerOrWriter  {
        _burn(account, amount);
    }
}
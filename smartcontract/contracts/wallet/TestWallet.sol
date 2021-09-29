pragma solidity >=0.6.0 <0.8.0;

import "../utils/ownable/MultiOwnable.sol";
import "../erc20/basic/IERC20.sol";
contract TestWallet is MultiOwnable{

    address public usdtAddress;
    event confirmEvent(address indexed sender,  address indexed target, uint256 amount);
    struct RequestType {
        uint actionType;
        uint256 amount;
        address target;
    }


    function confirm(address target, uint256 amount) public {    
        IERC20 usdt = IERC20(usdtAddress);
        usdt.transfer(target, amount);
        emit confirmEvent(msg.sender, target, amount);
    }
    
    function setUsdtAddress(address addr) public onlyOwner{
        usdtAddress = addr;
    }

} 


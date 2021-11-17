pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";

interface IWEUN is IERC20 {
    function deposit() external payable;

    function depositTo(address recipient) external payable;

    function withdraw(uint256 amount) external;

    function withdrawTo(address payable recipient, uint256 amount) external;

    function withdrawFrom(address sender, address payable recipient, uint256 amount) external;
}

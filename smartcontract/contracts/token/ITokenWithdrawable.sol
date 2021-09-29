pragma solidity >=0.6.0 <0.8.0;

interface ITokenWithdrawable{
    function submitWithdraw(address dest, uint256 amount, uint256 amountWithFee) external;

    function burn(address account, uint256 amount) external;
}
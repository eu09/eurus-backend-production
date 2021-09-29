pragma solidity >=0.6.0 <0.8.0;

interface ITokenMintable{
    function mint(address account, uint256 amount) external;
}

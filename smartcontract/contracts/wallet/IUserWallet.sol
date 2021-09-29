pragma solidity >=0.6.0 <0.8.0;

interface IUserWallet{

    event GasFeeTransferred(address indexed dest, uint256 indexed amount);

    function requestTransfer(address dest, string calldata assetName, uint256 amount, bytes calldata signature) external;

    function submitWithdraw(address dest, uint256 withdrawAmount, uint256 amountWithFee, string calldata assetName, bytes calldata signature) external;
}
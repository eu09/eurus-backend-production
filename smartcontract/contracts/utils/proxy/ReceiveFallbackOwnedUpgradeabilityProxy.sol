pragma solidity >=0.6.0 <0.8.0;

import "./OwnedUpgradeabilityProxy.sol";

contract ReceiveFallbackOwnedUpgradeabilityProxy is OwnedUpgradeabilityProxy {
    receive() external payable override {
        address _impl = implementation();
        require(_impl != address(0), "Implementation is 0");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}

pragma solidity >=0.6.0 <0.8.0;

import "./OwnedUpgradeabilityProxy.sol";

contract EtherForwardOwnedUpgradeabilityProxy is OwnedUpgradeabilityProxy {
    bytes32 private constant addressPosition = keccak256("eurus.proxy.etherforward.address");

    receive() external payable override {
        address addr = etherForwardAddress();
        require(addr != address(0), "Address is 0");
        payable(addr).transfer(msg.value);
    }

    function etherForwardAddress() public view returns (address addr) {
        bytes32 position = addressPosition;
        assembly {
            addr := sload(position)
        }
    }

    function setEtherForwardAddress(address ethForwardAddr) public onlyProxyOwner {
        address currentAddr = etherForwardAddress();
        require(currentAddr != ethForwardAddr);

        bytes32 position = addressPosition;
        assembly {
            sstore(position, ethForwardAddr)
        }
    }
}

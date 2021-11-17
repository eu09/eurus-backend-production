// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../basic/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
 abstract contract MultiOwnable is Context {
    address [] private ownerList;
    mapping (address => bool) private isOwnerMap;

    //mapping(address=>Account) public _owners;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        isOwnerMap[msgSender]=true;
        ownerList.push(msgSender);
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        address msgSender=_msgSender();
        require(isOwnerMap[msgSender]==true, "Ownable: caller is not one of the owner");
        _;
    }
    
     /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier isNotInOwners(address newOwner) {
        require(isOwnerMap[newOwner]!=true, "Address already is an owner");
        _;
    }


    modifier isInOwners(address owner) {
        require(isOwnerMap[owner], "Owner not exists");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        address msgSender = _msgSender();
        isOwnerMap[msgSender] = false;
        for (uint i=0; i<ownerList.length - 1; i++)
            if (ownerList[i] == msgSender) {
                ownerList[i] = ownerList[ownerList.length - 1];
                break;
            }
        ownerList.pop();
        
    }
    function addOwner(address newOwner) public 
        onlyOwner 
        isNotInOwners(newOwner){

        isOwnerMap[newOwner]=true;
        ownerList.push(newOwner);
        emit OwnerAdded(newOwner);
    }

    function getOwners()public view returns (address [] memory){

        return ownerList;
    }

    function removeOwner(address owner)
        public
        onlyOwner
        isInOwners(owner)
    {
        isOwnerMap[owner] = false;
        uint ownerCount = ownerList.length;
        for (uint i=0; i<ownerCount; i++){
            if (ownerList[i] == owner) {
                ownerList[i] = ownerList[ownerCount - 1];
                break;
            }
        }

        ownerList.pop();
        OwnerRemoved(owner);
    }

    function isOwner(address addr) public view returns(bool){
        return isOwnerMap[addr];
    }
    
    function getOwnerCount() public view returns(uint){
        return ownerList.length;
    }

}
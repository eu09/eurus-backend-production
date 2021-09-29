pragma solidity >=0.6.0 <0.8.0;

import "../utils/ownable/ReadWritePermissionable.sol";

abstract contract TxMultiSigWallet is ReadWritePermissionable{

    /*
     *  Events
     */
    event Confirmation(address indexed sender, bytes32 indexed transactionId);
    event Revocation(address indexed sender, bytes32 indexed transactionId);
    event Rejection(address indexed sender, bytes32 indexed transactionId);
    event Submission(bytes32 indexed transactionId);
    event Execution(bytes32 indexed transactionId);
    event ExecutionFailure(bytes32 indexed transactionId);
    event Deposit(address indexed sender, uint value);

    event RequirementChange(uint required);

    /*
     *  Constants
     */
    uint constant public MAX_OWNER_COUNT = 50;

    /*
     *  Storage
     */
    mapping (bytes32 => Transaction) public transactions;
    mapping (bytes32 => mapping (address => bool)) public confirmations;
    mapping (bytes32 => mapping (string=>string)) public miscellaneousData;
    uint public required;
    address public walletOwner;
    address[] public walletOperatorList; //this list also include walletOwner address
    mapping (address => bool) internal walletOperatorMap; //this map also incloue walletOwner address

    struct Transaction {
        bytes32 transHash;
        bool isDirectInvokeData;
        address destination;
        uint value;
        bytes data;
        uint timestamp;
        uint blockNumber;
        bool executed;
        bool rejected;
    }

    /*
     *  Modifiers
     */
    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier onlyWalletOperator() {
        require(walletOperatorMap[msg.sender] == true || walletOwner == msg.sender, "TxMultiSigWallet: caller is not one of the wallet operator");
        _;
    }

    modifier isNotWalletOperator(address inputAddress){
        require(walletOperatorMap[inputAddress] != true, "TxMultiSigWallet: Address is operator already");
        _;
    }

    modifier isWalletOwner(address inputAddress){
        require(walletOwner == inputAddress, "TxMultiSigWallet: caller is not wallet owner");
        _;
    }

    modifier isNotWalletOwner(address inputAddress){
     require(walletOwner != inputAddress, "TxMultiSigWallet: caller is wallet owner");
        _;
    }

    modifier transactionExists(bytes32 transactionId) {
        require(transactions[transactionId].destination != address(0), "TxMultiSigWallet: Transaction not found");
        _;
    }

    modifier confirmed(bytes32 transactionId, address owner) {
        require(confirmations[transactionId][owner], "TxMultiSigWallet: Transaction is not confirmed");
        _;
    }

    modifier notConfirmed(bytes32 transactionId, address owner) {
        require(!confirmations[transactionId][owner], "TxMultiSigWallet: Transaction is already confirmed");
        _;
    }

    modifier notExecuted(bytes32 transactionId) {
        require(!transactions[transactionId].executed, "TxMultiSigWallet: Transaction already executed");
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0), "TxMultiSigWallet: Address is null");
        _;
    }

    modifier validRequirement(uint _required) {
        require(_required != 0);
        _;
    }

    modifier notRejected(bytes32 transId){
        require(!transactions[transId].rejected, "TxMultiSigWallet: Transaction already rejected");
        _;
    }

    modifier rejected(bytes32 transId)
    {
        require(transactions[transId].rejected, "TxMultiSigWallet: Transaction is not rejected");
        _;
    }
    

    /// @dev Fallback function allows to deposit ether.
    receive()
        virtual external  payable
    {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param requiredCount Number of required confirmations.
    constructor(uint requiredCount) 
        validRequirement(requiredCount) internal
    {
        required = requiredCount;
    }


    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required)
        public
        onlyOwner
        validRequirement( _required)
    {
        required = _required;
        RequirementChange(_required);
    }

    function setWalletOwner(address addr) public
    onlyOwner{
        walletOwner = addr;
        if (!walletOperatorMap[walletOwner]){
            walletOperatorMap[walletOwner] = true; 
            walletOperatorList.push(walletOwner);
        }

    }

    function getWalletOwner()public view returns(address){
        return walletOwner;
    }


    function submitCustomTransaction(bytes32 transId) public 
        onlyWalletOperator 
        notConfirmed(transId, msg.sender)
        transactionExists(transId)
        notRejected(transId){

        confirmations[transId][msg.sender] = true;
        Confirmation(msg.sender, transId);
        executeTransaction(transId);
        
    }

    // /// @dev Allows an owner to confirm a transaction.
    // /// @param transactionId Transaction ID.
    // function confirmTransaction(uint transactionId) virtual 
    //     public
    //     onlyWalletOperator
    //     transactionExists(transactionId)
      
    // {
    //     confirmations[transactionId][msg.sender] = true;
    //     Confirmation(msg.sender, transactionId);
    //     executeTransaction(transactionId);
    // }
    
    function rejectTransaction(bytes32 transId) virtual public onlyWalletOperator
        transactionExists(transId)
        notConfirmed(transId, msg.sender)
        notRejected(transId)
        {
            transactions[transId].rejected = true;
            emit Rejection(msg.sender, transId);
        }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(bytes32 transactionId)
        public
        onlyWalletOperator
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
        notRejected(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        Revocation(msg.sender, transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(bytes32 transactionId) virtual internal
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            if (txn.isDirectInvokeData) {
                txn.executed = true;
                if (external_call(txn.destination, txn.value, txn.data))
                    Execution(transactionId);
                else {
                    ExecutionFailure(transactionId);
                    txn.executed = false;
                }
            }else{
                assert(false);
            }
        }
    }

    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(address destination, uint value, bytes memory data) internal returns (bool) {
        bool result;
        assembly {
            result := call(
                gas(),
                destination,
                value,
                add(data, 32),     // First 32 bytes are the padded length of data, so exclude that
                mload(data),       // Size of the input (in bytes) - this is what fixes the padding problem
                0,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(bytes32 transactionId)
        public
        view
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<walletOperatorList.length; i++) {
            if (confirmations[transactionId][walletOperatorList[i]])
                count += 1;
            if (count == required)
                return true;
        }
        return false;
    }

    function isRejected(bytes32 transId) public view returns(bool){
        return transactions[transId].rejected;
    }

    function addTransaction(bytes32 transHash, address destination, uint value, bytes memory data)
        internal
        notNull(destination)
    {
        Transaction storage checkTx = transactions[transHash];
        if (checkTx.transHash != transHash){
            transactions[transHash] = Transaction({
                transHash: transHash,
                isDirectInvokeData: true,
                destination: destination,
                value: value,
                data: data,
                timestamp: block.timestamp,
                blockNumber: block.number,
                executed: false,
                rejected: false
            });
            Submission(transHash);
        }
    }


    function getConfirmationCount(bytes32 transactionId)
        public
        view
        returns (uint count)
    {
        for (uint i=0; i<walletOperatorList.length; i++)
            if (confirmations[transactionId][walletOperatorList[i]])
                count += 1;
    }


    function getConfirmations(bytes32 transactionId)
        public
        view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](walletOperatorList.length);
        uint count = 0;
        uint i;
        for (i=0; i<walletOperatorList.length; i++)
            if (confirmations[transactionId][walletOperatorList[i]]) {
                confirmationsTemp[count] = walletOperatorList[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }


    function addWalletOperator(address operatorAddr) public 
        onlyOwner
        isNotWalletOperator(operatorAddr){
            
        walletOperatorMap[operatorAddr]=true;
        walletOperatorList.push(operatorAddr);
      
    }

    function removeWalletOperator(address operatorAddr) 
        public 
        onlyOwner
        isNotWalletOwner(operatorAddr)
    {
        require (operatorAddr != walletOwner, "Cannot remove wallet owner");

        walletOperatorMap[operatorAddr] = false;
        uint operatorCount = walletOperatorList.length;

        for (uint i=0; i<operatorCount - 1; i++){
            if (walletOperatorList[i] == operatorAddr) {
                walletOperatorList[i] = walletOperatorList[operatorCount - 1];
                break;
            }
        }
        walletOperatorList.pop();
    }

    function getWalletOperatorList() public view returns(address[] memory){
        return walletOperatorList;
    }

    function toBytes(address a) public pure returns (bytes memory) {
        return abi.encodePacked(a);
    }

}
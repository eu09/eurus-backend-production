pragma solidity >=0.6.0 <0.8.0;

import "./MultiOwnable.sol";
import "../basic/Context.sol";

 abstract contract ReadWritePermissionable is MultiOwnable{

    address [] internal readerList;
    mapping (address => bool) internal readerMap;

    address [] internal writerList;
    mapping (address => bool) internal writerMap;

    event ReaderAdded(address indexed reader);
    event ReaderRemoved(address indexed reader);
    event WriterAdded(address indexed writer);
    event WriterRemoved(address indexed writer);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {

    }


    // modifier onlyOwner (){
    //    onlyOwner();
    //    _;
    //}

    modifier isReaderExist(address newReader) {
        require (readerMap[newReader], "Reader not exist");
        _;
    }

    modifier isReaderNotExist(address newReader){
        require (!readerMap[newReader], "Reader already exists");
        _;
    }

    modifier isWriterExist(address newWriter) {
        require (writerMap[newWriter], "Writer not exist");
        _;
    }

    modifier isWriterNotExist(address newWriter){
        require (!writerMap[newWriter], "Writer already exists");
        _;
    }

    modifier onlyReader(address addr){
        require (readerMap[addr], "Reader only");
        _;
    }

    modifier onlyWriter(address addr){
        require (writerMap[addr], "Writer only");
        _;
    }

    modifier onlyOwnerOrWriter(){
        if (!isOwner(msg.sender) && !writerMap[msg.sender]){
            require(false, "Owner or writer only");
        }
        _;
    }

    function getReaderList()public view returns (address [] memory){
        return readerList;
    }

    function getWriterList()public view returns (address [] memory){
        return writerList;
    }

    function addReader(address newReader) public 
        onlyOwner 
        isReaderNotExist(newReader){
        readerMap[newReader]=true;
        readerList.push(newReader);
        emit ReaderAdded(newReader);
    }

    function addWriter(address newWriter) public 
        onlyOwner 
        isWriterNotExist(newWriter){
        writerMap[newWriter]=true;
        writerList.push(newWriter);
        emit WriterAdded(newWriter);
    }

    function removerReader(address existingReader)
        public
        onlyOwner
        isReaderExist(existingReader)
    {
        readerMap[existingReader] = false;
        uint readerCount = readerList.length;
        for (uint i=0; i<readerCount; i++){
            if (readerList[i] == existingReader) {
                readerList[i] = readerList[readerCount - 1];
                break;
            }
        }

        readerList.pop();
        ReaderRemoved(existingReader);
    }

    function removerWriter(address existingWriter)
        public
        onlyOwner
        isWriterExist(existingWriter)
    {
        writerMap[existingWriter] = false;
        uint writerCount = writerList.length;
        for (uint i=0; i<writerCount; i++){
            if (writerList[i] == existingWriter) {
                writerList[i] = writerList[writerCount - 1];
                break;
            }
        }

        writerList.pop();
        WriterRemoved(existingWriter);
    }

     function isWriter(address addr)public view returns (bool){
         return writerMap[addr];
     }
}
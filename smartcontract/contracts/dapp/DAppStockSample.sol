pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./DAppStockBase.sol";

contract DAppStockSample is DAppStockBase{

    mapping (uint256 => uint256) public productStockList;
    mapping(uint256 => uint256) public productSoldQuantityList;
    mapping(uint256 => uint256) public productSoldAmountList;
    ProductInfo[] public productList;
    mapping (uint256 => ProductInfo) public productMap;

    struct ProductInfo{
        uint256 productId;
        string name;
        uint256 price;
        bool onShelf;
    }

    struct PurchaseInfo{
        address buyer;
        uint256 quantity;
        bytes32 extraData;
    }

    mapping (uint256 => PurchaseInfo[]) public purchaseList;

    function purchaseImpl(address buyer, uint256 productId, uint256 quantity, string memory assetName, uint256 amount, bytes32 extraData) internal override onlyOwnerOrWriter{

        require(keccak256(abi.encodePacked(assetName)) == keccak256(abi.encodePacked("USDT")), "Only USDT is accepted");
        require(productMap[productId].onShelf, "Product is not available");

        require(productMap[productId].price * quantity == amount, "Invalid total amount");

        require(productStockList[productId] >= quantity, "Out of stock");

        uint256 updateStock = productStockList[productId] - quantity;
        productStockList[productId] = updateStock;
        
        PurchaseInfo[] storage purchaseInfoList = purchaseList[productId];
        purchaseInfoList.push(PurchaseInfo( {
            buyer: buyer, 
            quantity: quantity,
            extraData: extraData
        }));

        productSoldQuantityList[productId] = productSoldQuantityList[productId] + quantity;  
        productSoldAmountList[productId] = productSoldAmountList[productId] + amount;  
    }

    function addStock(uint256 productId, uint256 quantity) public onlyOwner{
        require(isProductOnShelf(productId), "Product does not exists");
        productStockList[productId] = productStockList[productId] + quantity;

    }

    function updateProduct(uint256 productId, uint256 quantity, uint256 price, string memory productName) public onlyOwner{
        if (!isProductOnShelf(productId)) {
            productList.push(ProductInfo({productId: productId, name: productName, price: price, onShelf: true}));
            productMap[productId] = ProductInfo({productId: productId, name: productName, price: price, onShelf: true});
        }
        addStock(productId, quantity);
    }

    function offShelfProduct(uint256 productId) public onlyOwner{
        productMap[productId].onShelf = false;
    }

    function getProductList() public view returns (ProductInfo[] memory){
        return productList;
    }

    function getProductStock(uint256 productId) public view returns (uint256){
        return productStockList[productId];
    }

    function isProductOnShelf(uint256 productId) public view returns (bool){
        return productMap[productId].onShelf;
    }

    function getPurchaseList(uint256 productId) public view returns (PurchaseInfo[] memory){
        return purchaseList[productId];
    }
    
}

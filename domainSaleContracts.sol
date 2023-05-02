//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// A sample contract issuing ERC721 tokens 

interface ERC20TokenContract{
    function balanceOf(address account) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract MyNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    constructor() ERC721("MyNFT", "MNFT") {}

    string[] public domainNames;
    
 
    function mintNFT(address _recipient, string memory _label) payable external returns(uint256) {
        

        tokenIds.increment();

        uint256 newItemId = tokenIds.current();
        _mint(_recipient, newItemId);
        _setTokenURI(newItemId, _label);
        

        return newItemId;
    }

    
}

// Domain sale Contract

contract domainSales is Ownable {
    
    address payable public contractOwner;
    uint8 private maxDiscountPercentAge = 20; 
    uint public salePrice;
    uint8 private defaultRefferalDiscount = 10; 
    
    // upadating when someone buys the domain 
    mapping(string => bool) public DomainsRegistered;
    mapping(string => address) public DomainOwningAddress;
    
    //event 
    event DomainNamePurchased(
        address indexed purchasedBy,
        string indexed domainNamePurchased
    );

    //whiteListing users for 20% discount 
    mapping(address => bool) public whiteListedAddresses;

    //re-entrancy variable
    bool transactionInProgress;

    constructor(){
        contractOwner = payable(msg.sender);
    }

    //creating a instance of 
    MyNFT myNft = new MyNFT();

    //setting sale prive
    function setSalePrice(uint _price) external onlyOwner {
        salePrice = _price;
    }

    //withdrawing any eth in the contract
    function withdraw() external onlyOwner{
        require(transactionInProgress == false, "a transaction is being processed");
        transactionInProgress = true;
        contractOwner.transfer(address(this).balance);
    }

    //setting refferal discount
    function setDefaultRefferalDiscount(uint8 _discount) external onlyOwner{
        require(_discount <= 20, "default refferal cannot go above 20 %");
        defaultRefferalDiscount = _discount;
    } 

    //whitlisting custom refferal discounts
    function addAddressToWhiteList(address _whiteListingAddress) external onlyOwner {
        whiteListedAddresses[_whiteListingAddress] = true;
    }

    //checking if domain available for sale
    function checkDomainAvailability(string memory domainName) public view returns(bool){
        return DomainsRegistered[domainName];
    }

    // seeing which address owns the doamain
    function domainBelongsTo(string memory domainName) public view returns(address){
        return DomainOwningAddress[domainName];
    }


    // buying the doamain without refferal and msg.value sent to contrcat owner directly
    function buyDomain(address _to, string memory _domainName) external payable{
        require(transactionInProgress == false, "a transaction is being processed");
        transactionInProgress = true;
        require(!checkDomainAvailability(_domainName), "Domain already registered");
        require(_to != address(0), "not a valid address");
        require(msg.value == salePrice, "you haven't sent enough eth");
    
        myNft.mintNFT(_to, _domainName);
        DomainsRegistered[_domainName] = true;
        DomainOwningAddress[_domainName] = _to;
        contractOwner.transfer(msg.value);

        emit DomainNamePurchased(_to, _domainName);
    }

    //buying domain with refferal and paying refferal amount to the one who gave the refferal
    function  buyDomainRefferal(address _to,string memory _domainName, string memory _refferedBy) external payable{
        require(transactionInProgress == false, "a transaction is being processed");
        transactionInProgress = true;
        require(!checkDomainAvailability(_domainName), "Domain already registered");
        require(DomainsRegistered[_refferedBy] == true, "your are not elibilbe to give refferal");
        require(_to != address(0), "not a valid address");
        require(msg.value == salePrice, "you haven't sent enough eth");

        myNft.mintNFT(_to, _domainName);
        DomainsRegistered[_domainName] = true;
        DomainOwningAddress[_domainName] = _to;

       if(whiteListedAddresses[DomainOwningAddress[_refferedBy]] == true){
           makePaymentThroughRefferal(20, msg.value, DomainOwningAddress[_refferedBy]);
           emit DomainNamePurchased(_to, _domainName);
       }
       else{
           makePaymentThroughRefferal(defaultRefferalDiscount, msg.value, DomainOwningAddress[_refferedBy]);
           emit DomainNamePurchased(_to, _domainName);
       }
    } 

    function makePaymentThroughRefferal(uint _discountPercent, uint _sentETH, address _refferedBy) private {
        uint256 refferalAmount = (_sentETH * _discountPercent ) / 100; 
            payable(_refferedBy).transfer(refferalAmount);
            contractOwner.transfer(_sentETH - refferalAmount);
    }

    
    //reserving doamins
    function reserveDomainsOnlyOwner(address _to, string memory _domainName) external onlyOwner {
        require(transactionInProgress == false, "a transaction is being processed");
        transactionInProgress = true;
        require(!checkDomainAvailability(_domainName), "Domain already registered");
        require(_to == address(0), "not a valid address");
        myNft.mintNFT(_to, _domainName);
        DomainsRegistered[_domainName] = true;
        DomainOwningAddress[_domainName] = _to;
        emit DomainNamePurchased(_to, _domainName);
    }


    //function to remove unwated ERC20 tokens
    function removeUnwantedTokens(address _tokenAddress) external onlyOwner{
        ERC20TokenContract erc20Tokens = ERC20TokenContract(_tokenAddress);
        uint bal = erc20Tokens.balanceOf(address(this));
        erc20Tokens.transfer(contractOwner, bal);
    }

}

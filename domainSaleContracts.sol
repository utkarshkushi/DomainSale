//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

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

contract domainSales {
    
    address payable public owner;
    uint8 private maxDiscountPercentAge = 20; 
    uint public salePrice;
    uint8 private refferalDiscount = 10; 
    
    // upadatinf when someone buys the domain 
    mapping(string => bool) public DomainsRegistered;
    mapping(string => address) public DomainOwningAddress;
    
    // this is for refferal system
    uint private refferalId = 1;
    mapping(uint256 => address) private refferedAddress;
    //this is public to know the refferal ID
    mapping(address => uint) public refferalIdOfRefferedAddress;
    mapping(uint256 => address) private refferalGivenBy;

    //checking if refferal id already used 
    mapping(uint256 => bool) private refferalIdUsed;

    modifier onlyOwner{
        require(msg.sender == owner, "only owner can call this function");
        _;
    }

    constructor(){
        owner = payable(msg.sender);
        // deployedContractAddress = _contractAddress;
    }

    //creating a instance of 
    MyNFT myNft = new MyNFT();

    //setting sale prive
    function setSalePrice(uint _price) external onlyOwner {
        salePrice = _price;
    }

    //withdrawing any eth in the contract
    function withdraw() external onlyOwner{
        owner.transfer(address(this).balance);
    }

    //setting refferal discount
    function setRefferalDiscount(uint8 _discount) external onlyOwner{
        refferalDiscount = _discount;
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
        require(!checkDomainAvailability(_domainName), "Domain already registered");
        require(_to != address(0), "not a valid address");
        require(msg.value == salePrice, "you haven't sent enough eth");
    
        myNft.mintNFT(_to, _domainName);
        DomainsRegistered[_domainName] = true;
        DomainOwningAddress[_domainName] = _to;
        owner.transfer(msg.value);
    }

    //buying domain with refferal and paying refferal amount to the one who gave the refferal
    function  buyDomainRefferal(address _to,string memory _domainName, uint256 _refferralId) external payable{
        require(!checkDomainAvailability(_domainName), "Domain already registered");
        require(refferedAddress[_refferralId] != address(0), "not a valid referral address");
        require(refferalIdUsed[_refferralId] == false, "refferal Id already used");
        require(_to != address(0), "not a valid address");
        require(msg.value == salePrice, "you haven't sent enough eth");

        myNft.mintNFT(_to, _domainName);
        DomainsRegistered[_domainName] = true;
        DomainOwningAddress[_domainName] = _to;

        refferalIdUsed[_refferralId] = true;

        uint256 refferalAmount = (msg.value * refferalDiscount ) / 100; 
        payable(refferalGivenBy[_refferralId]).transfer(refferalAmount);
        owner.transfer(msg.value - refferalAmount);

    } 

    
    //reserving doamins
    function reserveDomainsOnlyOwner(address _to, string memory _domainName) external onlyOwner {
        require(!checkDomainAvailability(_domainName), "Domain already registered");
        require(_to == address(0), "not a valid address");
        myNft.mintNFT(_to, _domainName);
        DomainsRegistered[_domainName] = true;
        DomainOwningAddress[_domainName] = _to;
    }


    //giving refferal
    function giveRefferal(string memory _existingDomain, address _refferingTo) external {
        require(DomainOwningAddress[_existingDomain] != address(0), "you dont have a domain to reffer others");
        require(msg.sender == DomainOwningAddress[_existingDomain], "you are not allowed to give refferal");
        refferedAddress[refferalId] = _refferingTo;
        refferalIdOfRefferedAddress[_refferingTo] = refferalId;
        refferalGivenBy[refferalId] = DomainOwningAddress[_existingDomain];
        refferalIdUsed[refferalId] = false;
        refferalId++;

    }

    //function to remove unwated ERC20 tokens
    function removeUnwantedTokens(address _tokenAddress) external onlyOwner{
        ERC20TokenContract erc20Tokens = ERC20TokenContract(_tokenAddress);
        uint bal = erc20Tokens.balanceOf(address(this));
        erc20Tokens.transfer(owner, bal);
    }

}

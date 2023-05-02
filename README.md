# Domain Sale
- In the above code, setDefaultRefferalDiscount() sets the default refferal percentage keeping it 10% in the begining and not exceeding 20%. And a whiteListing function and mapping that whitelists address by owner to get 20% refferal percent.
But i feel there is another way we are trying to solve this , that is we cannot change the defaultRefferalDiscount but can whiteList addresses to avail refferal percentage upto 20%. 
in this case we would change the mapping to 
mapping(address => uint) public whiteListedAddresses;

and would add a setWhiteListRefferal that would set the refferal percentage
function setWhiteListRefferal(address _to, uint _per) external onlyOwner{
  whiteListedAddresses[_to] = _per;
 }
 
 and during the domainSaleThroughRefferal would add a check 
 require( whiteListedAddresses[_refferedBy] > 0 , "not white listed");
 and give the custom refferal percentage
 
 ## If latter is the case please tell me so that i can make the changes

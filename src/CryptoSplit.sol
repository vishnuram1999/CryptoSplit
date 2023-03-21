//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract CryptoSplit is ReentrancyGuard {
  AggregatorV3Interface internal priceFeed;

  // events initialization
  event Received(address, uint);
  event sentDonations(address, uint);

  // errors
  error notOwner();
  error notMember(address, string);
  error notValidAddress(address, string);
  error notGroupMember(string);
  
  address public owner;
  uint internal idNumber;

  // declaring the constructor with the owner to contract and idNumber
  constructor() payable {
    owner = msg.sender;
    idNumber = 0;
    priceFeed = AggregatorV3Interface(0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43);
  }
  
  // modifier to identify the transaction sender is owner or not
  modifier onlyOwner() {
    if(msg.sender == owner) {
        revert notOwner();
    }
    _;
  }
 
  // modifier to identify the transaction sender is member of moneysplit application
  modifier onlyMember() {
    if(msg.sender != members[msg.sender].id || msg.sender == address(0x0)) {
        revert notMember(msg.sender, "Not an member, Create account or Not a valid address");
    }
    _;
  }

  // modifier to identify the transaction sender is member of specific group or not
  modifier onlyGroupMember(string calldata _groupName) {
    uint256 count = 0;
    for (uint i=0; i<groups[_groupName].groupMembers.length; i++) {
        if(msg.sender != groups[_groupName].groupMembers[i]) {
            count++;
        }
    }
    if (count == groups[_groupName].groupMembers.length) {
        revert notGroupMember("You don't belong to this group");
    }
    _;
  }

  // initialization of structure - Member 
  struct Member {
    address id;
    string name;
    uint amountSpend;
    mapping(string => uint) expenses;
    mapping(address => mapping(address => uint)) balances;
    address[] friends;
  }
  
  // initialization of structure - Group
  struct Group {
    address[] groupMembers;
    uint groupExpense;
    mapping(string => uint) groupExpensesNameList;
  }
  
  mapping(address => Member) public members; // initialization of mapping (dictionary) with key address and value Member structure
  mapping(string => Group) public groups; // initialization of mapping (dictionary) with key string and value Group structure

  // declaration of function to create a account in moneysplit
  function createAccount(string memory _name) public returns(string memory) {
    require(address(msg.sender) != address(0x0), "Not Valid an address"); // to verify it is not an address(0)
    require(members[address(msg.sender)].id != address(msg.sender), "You already have an account"); // to verify whether the transaction sender is not having an account already
    members[address(msg.sender)].id = address(msg.sender);
    members[address(msg.sender)].name = _name;
    members[address(msg.sender)].amountSpend = 0;
    idNumber += 1;
    return "You got an account!!!";
  }

  // decalaration of function to view your expenses so for
  function showExpense() public view onlyMember returns (uint) {
    return members[address(msg.sender)].amountSpend;
  }
  
  // function to show expense of specific member in moneysplit but only owner can view it
  function showExpenseOfMember(address _id) public view onlyMember returns (uint) {
    return members[address(_id)].amountSpend;
  }
  
  // function to add your expense
  function addExpense(string memory _expenseName, uint _amount, address _paidID, address tokenAddress) public onlyMember {
    members[address(msg.sender)].amountSpend += _amount;
    members[address(msg.sender)].expenses[_expenseName] = _amount;
    if (address(msg.sender) != address(_paidID)) {
        members[address(msg.sender)].balances[address(_paidID)][tokenAddress] = _amount;
    }
  }
  
  // function to create a group with specific members
  function createGroup(string memory _groupName, address[] memory _group) public onlyMember{ 
    for (uint i = 0; i < _group.length;) {
        if(_group[i] != members[_group[i]].id || _group[i] == address(0x0)) {
            revert notMember(msg.sender, "Not an member, Create account or Not a valid address");
        }
        unchecked {
            ++i;
        }
    }
    groups[_groupName].groupMembers = _group;
    groups[_groupName].groupExpense = 0;
  }

  // function to add a member to existing the group but only member of that group can do this
  function addMemberToGroup(string calldata _groupName, address _id) public onlyMember onlyGroupMember(_groupName) {
      for (uint i=0; i<groups[_groupName].groupMembers.length; ++i) {
        require(_id != groups[_groupName].groupMembers[i], "Address already exists in this group!!!");
      }
      groups[_groupName].groupMembers.push(_id);
  }

  // function to remove a member from existing the group but only member of that group can do this 
  function removeMemberFromGroup(string calldata _groupName, address _id) public onlyMember onlyGroupMember(_groupName) {
    //get the index of address in the array
    uint index = 0;
    for (uint j=0; j<groups[_groupName].groupMembers.length-1; j++) {
      if(address(_id) == address(groups[_groupName].groupMembers[j])) {
          index = j;
      }
    }
    for (uint256 i = index; i < groups[_groupName].groupMembers.length - 1; i++) {
      groups[_groupName].groupMembers[i] = groups[_groupName].groupMembers[i+1];
    }
    groups[_groupName].groupMembers.pop(); // delete the last item
  }

  // function to add a group expense equally between the group memebers
  function addExpenseEqualBetweenGroup(string calldata _expenseName, string calldata _groupName, uint _amount, address _tokenAddress, address _paidID) public onlyMember onlyGroupMember(_groupName) {
      require(groups[_groupName].groupMembers.length != 0, "Group doesn't exist");
      uint256 lengthOfArray = groups[_groupName].groupMembers.length;
      uint256 amountPerMember = _amount / lengthOfArray;
      groups[_groupName].groupExpense += _amount;
      groups[_groupName].groupExpensesNameList[_expenseName] = _amount;
      for (uint i = 0; i < lengthOfArray;) {
            members[address(groups[_groupName].groupMembers[i])].amountSpend += amountPerMember;
            members[address(groups[_groupName].groupMembers[i])].expenses[_expenseName] = amountPerMember;
            if(address(groups[_groupName].groupMembers[i]) != address(_paidID)) {
                members[address(groups[_groupName].groupMembers[i])].balances[address(_paidID)][_tokenAddress] = amountPerMember;
            }
            unchecked {
              ++i;
            }
        }
  }

  // function to add a group expense unequally between the group memebers with their respective portions
  function addExpenseUnequalBetweenGroup(string calldata _expenseName, string calldata _groupName, uint _amount, address _tokenAddress, uint[] calldata _portions, address _paidID) public onlyMember onlyGroupMember(_groupName) {
    require(groups[_groupName].groupMembers.length != 0, "Group doesn't exist");
    uint256 lengthOfList = _portions.length;
    uint256 sum = 0;
    for (uint i = 0; i < lengthOfList;) {
        sum += _portions[i];
        unchecked {
          ++i;
        }
    }
    require(_amount == sum, "Total amount and portions are mismatching, Check Again");
    groups[_groupName].groupExpense += _amount;
    groups[_groupName].groupExpensesNameList[_expenseName] = _amount;
    for (uint i = 0; i < lengthOfList;) {
        members[address(groups[_groupName].groupMembers[i])].amountSpend += _portions[i];
        members[address(groups[_groupName].groupMembers[i])].expenses[_expenseName] = _portions[i];
        if(address(groups[_groupName].groupMembers[i]) != address(_paidID)) {
          members[address(groups[_groupName].groupMembers[i])].balances[address(_paidID)][_tokenAddress] = _portions[i];
        }
        unchecked {
            ++i;
        }
    }
  }

  // function to show the expense of the group
  function showExpenseOfGroup(string calldata _groupName) public view onlyMember onlyGroupMember(_groupName) returns(uint) {
    return groups[_groupName].groupExpense;
  }

  // function to search for an expense with the expense name (string)
  function findExpense(string calldata _expenseName) view public onlyMember returns(string memory, uint) {
    return (_expenseName, members[address(msg.sender)].expenses[_expenseName]);
  }

  // function to settle the balance to another member and to avoid the reentrancy attack "nonReentrant" modifier is used
  function settleBalanceInEther(address payable _toID, uint _amount, address _tokenAddress) onlyMember external payable nonReentrant {
    // sending the ether to another EOA
    members[address(msg.sender)].balances[address(_toID)][_tokenAddress] -= _amount;
    (bool sent,) = _toID.call{value: _amount}("");
    require(sent, "Failed to send balance");
    
  }

  function settleBalanceInERC20Token(address tokenAddress, address payable _toID, uint _amount, address _tokenAddress) onlyMember external payable nonReentrant {
    members[address(msg.sender)].balances[address(_toID)][_tokenAddress] -= _amount;
    ERC20(tokenAddress).transfer(_toID, _amount);
  }

  // Users can send owner donation to help consistently improve the platform 
  // to receive the ethers which come towards the contract with call data in the transation
  receive() external payable {
    emit Received(msg.sender, msg.value); // emit an event to register the receival
  }

  // to receive the ethers which come towards the contract without call data in the transaction
  fallback() external payable {
    emit Received(msg.sender, msg.value); // emit an event to register the receival
  }

  // to send the ether recevied to the owner of this contract
  function sendDonationsToOwner(uint _amount) external payable onlyOwner nonReentrant {
    (bool sent,) = address(this).call{value: _amount}("");
    require(sent, "Failed to send donations to owner");
    emit sentDonations(address(msg.sender), _amount); // emit an event to register the sending the ether to owner
  }

  // to see all gorup members
  function showGroupMembers(string calldata _groupName) view public onlyMember onlyGroupMember(_groupName) returns(address[] memory) {
    return groups[_groupName].groupMembers;
  }

  // to see the our balance to pay someone else
  function showBalances(address _addr, address _tokenAddress) view public onlyMember returns(uint) {
    return members[msg.sender].balances[_addr][_tokenAddress];
  }

  function getLatestPrice() public view returns (int) {
    (,int price,,,) = priceFeed.latestRoundData();
    return price;
  }
}

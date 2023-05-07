//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @author Vishnuram Rajkumar (aka viking71)

contract CryptoSplit is ReentrancyGuard {
  AggregatorV3Interface internal priceFeed; // chainlink oracle

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
  constructor() {
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
    uint amountSpend;
    mapping(string => uint) expenses;
    mapping(address => mapping(address => uint)) balances;
    address[] friends;
    string[] groups;
    string[] expensesName;
    address[] balanceAddresses;
  }
  
  // initialization of structure - Group
  struct Group {
    address[] groupMembers;
    uint groupExpense;
    mapping(string => uint) groupExpensesNameList;
  }
  
  mapping(address => Member) public members; // initialization of mapping (dictionary) with key address and value Member structure
  mapping(string => Group) public groups; // initialization of mapping (dictionary) with key string and value Group structure

  // decalaration of function to view your expenses so for
  function showExpense() public view returns (uint) {
    return members[address(msg.sender)].amountSpend;
  }
  
  // function to show expense of specific member in moneysplit but only owner can view it
  function showExpenseOfMember(address _id) public view returns (uint) {
    return members[address(_id)].amountSpend;
  }
  
  // function to add your expense
  function addExpense(string memory _expenseName, uint _amount, address _paidID, address tokenAddress) public  {
    members[msg.sender].expensesName.push(_expenseName);
    members[msg.sender].amountSpend += _amount;
    members[msg.sender].expenses[_expenseName] = _amount; // this should be in terms of dollars
    // only if the expense is paid by different person for you then balance is updated
    if (msg.sender != _paidID) {
        members[msg.sender].balances[_paidID][tokenAddress] += _amount; // this should be in terms of token value
        members[msg.sender].balanceAddresses.push(_paidID);
    }
  }
  
  // function to create a group with specific members
  function createGroup(string memory _groupName, address[] memory _group) public { 
    for (uint i = 0; i < _group.length;) {
        if(_group[i] == address(0x0)) {
            revert notMember(msg.sender, "Not a valid address");
        }
        members[_group[i]].groups.push(_groupName);
        unchecked {
            ++i;
        }
    }
    groups[_groupName].groupMembers = _group;
    groups[_groupName].groupExpense = 0;
  }

  // function to add a member to existing the group but only member of that group can do this
  function addMemberToGroup(string calldata _groupName, address _id) public onlyGroupMember(_groupName) {
      for (uint i=0; i<groups[_groupName].groupMembers.length; ++i) {
        require(_id != groups[_groupName].groupMembers[i], "Address already exists in this group!!!");
      }
      groups[_groupName].groupMembers.push(_id);
  }

  // function to remove a member from existing the group but only member of that group can do this 
  function removeMemberFromGroup(string calldata _groupName, address _id) public onlyGroupMember(_groupName) {
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
  function addExpenseEqualBetweenGroup(string calldata _expenseName, string calldata _groupName, uint _amount, address _tokenAddress, address _paidID) public  onlyGroupMember(_groupName) {
      require(groups[_groupName].groupMembers.length != 0, "Group doesn't exist");
      uint256 lengthOfArray = groups[_groupName].groupMembers.length;
      uint256 amountPerMember = _amount / lengthOfArray;
      groups[_groupName].groupExpense += _amount;
      groups[_groupName].groupExpensesNameList[_expenseName] = _amount;
      for (uint i = 0; i < lengthOfArray;) {
            members[address(groups[_groupName].groupMembers[i])].amountSpend += amountPerMember;
            members[address(groups[_groupName].groupMembers[i])].expenses[_expenseName] += amountPerMember;
            if(address(groups[_groupName].groupMembers[i]) != address(_paidID)) {
                members[address(groups[_groupName].groupMembers[i])].balances[address(_paidID)][_tokenAddress] += amountPerMember;
            }
            unchecked {
              ++i;
            }
        }
  }

  // function to add a group expense unequally between the group memebers with their respective portions
  function addExpenseUnequalBetweenGroup(string calldata _expenseName, string calldata _groupName, uint _amount, address _tokenAddress, uint[] calldata _portions, address _paidID) public onlyGroupMember(_groupName) {
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
        members[address(groups[_groupName].groupMembers[i])].expenses[_expenseName] += _portions[i];
        if(address(groups[_groupName].groupMembers[i]) != address(_paidID)) {
          members[address(groups[_groupName].groupMembers[i])].balances[address(_paidID)][_tokenAddress] += _portions[i];
        }
        unchecked {
            ++i;
        }
    }
  }

  // function to show the expense of the group
  function showExpenseOfGroup(string calldata _groupName) public view onlyGroupMember(_groupName) returns(uint) {
    return groups[_groupName].groupExpense;
  }

  // function to search for an expense with the expense name (string)
  function findExpense(string calldata _expenseName) view public  returns(string memory, uint) {
    return (_expenseName, members[address(msg.sender)].expenses[_expenseName]);
  }

  // function to settle the balance to another member and to avoid the reentrancy attack "nonReentrant" modifier is used
  function settleBalanceInEther(address payable _toID, uint _amount, address _tokenAddress)  external payable nonReentrant {
    // sending the ether to another EOA
    members[address(msg.sender)].balances[address(_toID)][_tokenAddress] -= _amount;
    (bool sent,) = _toID.call{value: _amount}("");
    require(sent, "Failed to send balance");
    
  }

  function settleBalanceInERC20Token(address tokenAddress, address payable _toID, uint _amount, address _tokenAddress)  external payable nonReentrant {
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
  function showGroupMembers(string calldata _groupName) view public onlyGroupMember(_groupName) returns(address[] memory) {
    return groups[_groupName].groupMembers;
  }

  // to see the our balance to pay someone else
  function showBalances(address _addr, address _tokenAddress) view public  returns(uint256) {
    return members[msg.sender].balances[_addr][_tokenAddress];
  }

  function showGroups() view public returns(string[] memory) {
    return members[msg.sender].groups;
  }

  function showExpenses() public view returns(string[] memory) {
    return members[msg.sender].expensesName;
  }

  function showExpenseAmount(string memory _expenseName) public view returns(uint256) {
    return members[msg.sender].expenses[_expenseName];
  }

  function showBalanceAddresses() public view returns(address[] memory) {
    return members[msg.sender].balanceAddresses;
  }

  function getLatestPrice() public view returns(int) {
    (,int price,,,) = priceFeed.latestRoundData();
    return price;
  }
}

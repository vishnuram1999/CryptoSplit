pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

error notOwner();
error notMember(address, string);

contract MoneySplit {

  address public owner;
  uint internal idNumber;

  constructor() payable {
    // what should we do on deploy?
    owner = msg.sender;
    idNumber = 0;
  }

  modifier onlyOwner() {
    if(msg.sender == owner) {
        revert notOwner();
    }
    _;
  }

  struct Member {
      address id;
      string name;
      uint amountSpend;
      mapping(string => uint) expenses;
      mapping(address => uint) balances;
  }

  struct Group {
      address[] groupMembers;
      uint groupExpense;
      mapping(string => uint) groupExpensesNameList;
  }

  mapping(address => Member) public members;
  mapping(string => Group) public groups;

  function createAccount(string memory _name) public returns(string memory) {
        members[address(msg.sender)].id = address(msg.sender);
        members[address(msg.sender)].name = _name;
        members[address(msg.sender)].amountSpend = 0;
        idNumber += 1;
        return "You got an account!!!";
    }

  function showExpense() public view returns (uint) {
      require(members[address(msg.sender)].id != address(0x0), "You don't have an account, Create one!");
      return members[address(msg.sender)].amountSpend;
  }

  function showExpenseOfMember(address _id) public view returns (uint) {
      require(members[address(_id)].id != address(0x0), "You don't have an account, Create one!");
      return members[address(_id)].amountSpend;
  }

  function addExpense(string memory _expenseName, uint _amount, address _paidID) public {
      require(members[address(msg.sender)].id != address(0x0), "You don't have an account, Create one!");
      members[address(msg.sender)].amountSpend += _amount;
      members[address(msg.sender)].expenses[_expenseName] = _amount;
      if (address(msg.sender) != address(_paidID)) {
          members[address(msg.sender)].balances[address(_paidID)] = _amount;
      }
  }

  function createGroup(string memory _groupName, address[] memory _group) public { 
      for (uint i = 0; i < _group.length;) {
          if(members[address(_group[i])].id == address(0x0)) {
              revert notMember(members[address(_group[i])].id, "is not a member");
          }
          unchecked {
              ++i;
          }
      }
      groups[_groupName].groupMembers = _group;
      groups[_groupName].groupExpense = 0;
  }

  function addMemberToGroup(string calldata _groupName, address _id) public {
      require(members[address(_id)].id != address(0x0), "Address is not a member");
      groups[_groupName].groupMembers.push(_id);
  }

  function removeMemberToGroup(string calldata _groupName, address _id) public {
      require(members[address(_id)].id != address(0x0), "Address is not a member");
      uint i = 0;
      while (groups[_groupName].groupMembers[i] != _id) {
          i++;
      }
      for (uint j=i; j<groups[_groupName].groupMembers.length-1;j++) {
          groups[_groupName].groupMembers[j] = groups[_groupName].groupMembers[j+1];
      }
      delete groups[_groupName].groupMembers[groups[_groupName].groupMembers.length - 1];
  }

  function addExpenseEqualBetweenGroup(string calldata _expenseName, string calldata _groupName, uint _amount, address _paidID) public {
      require(groups[_groupName].groupMembers.length != 0, "Group doesn't exist");
      uint256 lengthOfArray = groups[_groupName].groupMembers.length;
      uint256 amountPerMember = _amount / lengthOfArray;
      groups[_groupName].groupExpense += _amount;
      groups[_groupName].groupExpensesNameList[_expenseName] = _amount;
      for (uint i = 0; i < lengthOfArray;) {
          members[address(groups[_groupName].groupMembers[i])].amountSpend += amountPerMember;
          members[address(groups[_groupName].groupMembers[i])].expenses[_expenseName] = amountPerMember;
          if(address(groups[_groupName].groupMembers[i]) != address(_paidID)) {
              members[address(groups[_groupName].groupMembers[i])].balances[address(_paidID)] = amountPerMember;
          }
          unchecked {
              ++i;
          }
      }
  }

  function addExpenseUnequalBetweenGroup(string calldata _expenseName, string calldata _groupName, uint _amount, uint[] calldata _portions, address _paidID) public {
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
              members[address(groups[_groupName].groupMembers[i])].balances[address(_paidID)] = _portions[i];
          }
          unchecked {
              ++i;
          }
      }
  }

  function showExpenseOfGroup(string calldata _groupName) public view returns(uint) {
      return groups[_groupName].groupExpense;
  }

  function findExpense(string calldata _expenseName) view public returns(string memory, uint) {
      return (_expenseName, members[address(msg.sender)].expenses[_expenseName]);
  }

  function settleBalance(address _id, uint _amount) public {
      members[address(msg.sender)].balances[address(_id)] -= _amount;
  }
}

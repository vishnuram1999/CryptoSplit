//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

error notOwner();
error notMember(address, string);

contract MoneySplit {

  address public owner;
  uint internal idNumber;

  constructor() payable {
    owner = msg.sender;
    idNumber = 0;
  }

  modifier onlyOwner() {
    if(msg.sender == owner) {
        revert notOwner();
    }
    _;
  }

  modifier onlyMember() {
    if(msg.sender != members[msg.sender].id || msg.sender == address(0x0)) {
        revert notMember(msg.sender, "Not an member, Create account");
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
        require(address(msg.sender) != address(0x0), "Not Valid an address");
        require(members[address(msg.sender)].id != address(msg.sender), "You already have an account");
        members[address(msg.sender)].id = address(msg.sender);
        members[address(msg.sender)].name = _name;
        members[address(msg.sender)].amountSpend = 0;
        idNumber += 1;
        return "You got an account!!!";
    }

  function showExpense() public view onlyMember returns (uint) {
      return members[address(msg.sender)].amountSpend;
  }

  function showExpenseOfMember(address _id) public view onlyMember returns (uint) {
      return members[address(_id)].amountSpend;
  }

  function addExpense(string memory _expenseName, uint _amount, address _paidID) public onlyOwner {
      members[address(msg.sender)].amountSpend += _amount;
      members[address(msg.sender)].expenses[_expenseName] = _amount;
      if (address(msg.sender) != address(_paidID)) {
          members[address(msg.sender)].balances[address(_paidID)] = _amount;
      }
  }

  function createGroup(string memory _groupName, address[] memory _group) public onlyOwner { 
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

  function addMemberToGroup(string calldata _groupName, address _id) public onlyMember {
      groups[_groupName].groupMembers.push(_id);
  }

  function removeMemberToGroup(string calldata _groupName, address _id) public onlyMember {
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

  function addExpenseEqualBetweenGroup(string calldata _expenseName, string calldata _groupName, uint _amount, address _paidID) public onlyMember {
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

  function addExpenseUnequalBetweenGroup(string calldata _expenseName, string calldata _groupName, uint _amount, uint[] calldata _portions, address _paidID) public onlyMember {
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

  function showExpenseOfGroup(string calldata _groupName) public view onlyMember returns(uint) {
      return groups[_groupName].groupExpense;
  }

  function findExpense(string calldata _expenseName) view public onlyMember returns(string memory, uint) {
      return (_expenseName, members[address(msg.sender)].expenses[_expenseName]);
  }

  function settleBalance(address _id, uint _amount) onlyMember public {
      members[address(msg.sender)].balances[address(_id)] -= _amount;
  }
}

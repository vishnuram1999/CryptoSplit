//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

error notOwner();
error notMember(address, string);
error notValidAddress(address, string);
error notGroupMember(string);

contract MoneySplit {

  event Received(address, uint);
  event sentDonations(address, uint);
  
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
        revert notMember(msg.sender, "Not an member, Create account or Not a valid address");
    }
    _;
  }

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

  struct Member {
      address id;
      string name;
      uint amountSpend;
      mapping(string => uint) expenses;
      mapping(address => uint) balances;
      address[] friends;
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

  function addExpense(string memory _expenseName, uint _amount, address _paidID) public onlyMember {
      members[address(msg.sender)].amountSpend += _amount;
      members[address(msg.sender)].expenses[_expenseName] = _amount;
      if (address(msg.sender) != address(_paidID)) {
          members[address(msg.sender)].balances[address(_paidID)] = _amount;
      }
  }

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

  function addMemberToGroup(string calldata _groupName, address _id) public onlyMember onlyGroupMember(_groupName) {
      for (uint i=0; i<groups[_groupName].groupMembers.length; ++i) {
        require(_id != groups[_groupName].groupMembers[i], "Address already exists in this group!!!");
      }
      groups[_groupName].groupMembers.push(_id);
  }

  function removeMemberFromGroup(string calldata _groupName, address _id) public onlyMember onlyGroupMember(_groupName) {
      uint i = 0;
      while (groups[_groupName].groupMembers[i] != _id) {
          i++;
      }
      for (uint j=i; j<groups[_groupName].groupMembers.length-1;j++) {
          groups[_groupName].groupMembers[j] = groups[_groupName].groupMembers[j+1];
      }
      delete groups[_groupName].groupMembers[groups[_groupName].groupMembers.length - 1];
  }

  function addExpenseEqualBetweenGroup(string calldata _expenseName, string calldata _groupName, uint _amount, address _paidID) public onlyMember onlyGroupMember(_groupName) {
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

  function addExpenseUnequalBetweenGroup(string calldata _expenseName, string calldata _groupName, uint _amount, uint[] calldata _portions, address _paidID) public onlyMember onlyGroupMember(_groupName) {
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

  function showExpenseOfGroup(string calldata _groupName) public view onlyMember onlyGroupMember(_groupName) returns(uint) {
      return groups[_groupName].groupExpense;
  }

  function findExpense(string calldata _expenseName) view public onlyMember returns(string memory, uint) {
      return (_expenseName, members[address(msg.sender)].expenses[_expenseName]);
  }

  function settleBalance(address payable _toID, uint _amount) onlyMember public payable {
    members[address(msg.sender)].balances[address(_toID)] -= _amount;
    //   (bool sent, bytes memory data) = _toID.call{value: _amount}("");
    //   require(sent, "Failed to send balance");
  }

    // Users can send owner donation to help consistently improve the platform 
  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  fallback() external payable {
    emit Received(msg.sender, msg.value);
  }

  function sendDonationsToOwner(uint _amount) public payable onlyOwner {
    (bool sent, bytes memory data) = address(this).call{value: _amount}("");
    require(sent, "Failed to send donations to owner");
    emit sentDonations(address(msg.sender), _amount);
  }
}

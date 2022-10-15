// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

error notOwner();
error notMember(address, string);

contract MoneySplit {

    address public owner;
    uint public idNumber;

    constructor() {
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
    }

    struct Group {
        address[] groupMembers;
        uint groupExpense;
        mapping(string => uint) groupExpensesNameList;
    }

    mapping(address => Member) public members;
    mapping(string => Group) public groups;

    function createAccount(string memory _name) public {
        members[address(msg.sender)].id = address(msg.sender);
        members[address(msg.sender)].name = _name;
        members[address(msg.sender)].amountSpend = 0;
        idNumber += 1;
    }

    function showExpense() public view returns (uint) {
        require(members[address(msg.sender)].id != address(0x0), "You don't have an account, Create one!");
        return members[address(msg.sender)].amountSpend;
    }

    function showExpenseOfMember(address _id) public view returns (uint) {
        require(members[address(_id)].id != address(0x0), "You don't have an account, Create one!");
        return members[address(_id)].amountSpend;
    }

    function addExpense(string memory _expenseName, uint _amount) public {
        require(members[address(msg.sender)].id != address(0x0), "You don't have an account, Create one!");
        members[address(msg.sender)].amountSpend += _amount;
        members[address(msg.sender)].expenses[_expenseName] = _amount;
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

    function addExpenseEqualBetweenGroup(string calldata _expenseName, string calldata _groupName, uint _amount) public {
        require(groups[_groupName].groupMembers.length != 0, "Group doesn't exist");
        uint256 lengthOfArray = groups[_groupName].groupMembers.length;
        uint256 amountPerMember = _amount / lengthOfArray;
        groups[_groupName].groupExpense += _amount;
        groups[_groupName].groupExpensesNameList[_expenseName] = _amount;
        for (uint i = 0; i < lengthOfArray;) {
            members[address(groups[_groupName].groupMembers[i])].amountSpend += amountPerMember;
            members[address(groups[_groupName].groupMembers[i])].expenses[_expenseName] = amountPerMember;
            unchecked {
                ++i;
            }
        }
    }

    function addExpenseUnequalBetweenGroup(string calldata _expenseName, string calldata _groupName, uint _amount, uint[] calldata _portions) public {
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

}

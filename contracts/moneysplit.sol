pragma solidity ^0.8.1;

contract moneysplit {

    struct member {
        address id;
        uint accountBalance;
        string name;
        uint amountSpend;
    }

    struct expense {
        uint expenseAmount;
        string expenseName;
    }

    uint public id_number = 0;

    member[] public members;
    expense[] public expenses;

    mapping(address => uint) public idToAddress;

    function addMembers(address id, uint accountBalance, string memory name, uint amountSpend) public {
        members.push(member({id: id, accountBalance: accountBalance, name: name, amountSpend: amountSpend}));
        idToAddress[id] = id_number;
        id_number++;
    }

    function showMembers() public view returns (member[] memory) {
        return members;
    }

    function equalSplit(uint totalAmount, uint noOfmembers) public pure returns (uint) {
        uint amountPerPerson = totalAmount / noOfmembers;
        return amountPerPerson;
    }

    function addExpense(uint amount, string memory description, uint option, uint[] memory uneqamt) public {
        if(option == 1) {
            uint amt = equalSplit(amount, members.length);
            for (uint i = 0; i < members.length; i++) {
                members[i].amountSpend = members[i].amountSpend + amt;
                members[i].accountBalance = members[i].accountBalance - amt;
            }
        }
        else {
            for (uint i = 0; i < members.length; i++) {
                members[i].amountSpend = members[i].amountSpend + uneqamt[i];
                members[i].accountBalance = members[i].accountBalance - uneqamt[i];
            }
        }
        expenses.push(expense({expenseAmount: amount, expenseName: description}));
    }

    function showExpense() public view returns (expense[] memory) {
        return expenses;
    }

    function giveAmount(address fromId, address toId, uint amount) public{
        uint id1 = idToAddress[fromId];
        uint id2 = idToAddress[toId];
        members[id1].accountBalance = members[id1].accountBalance - amount;
        members[id2].accountBalance= members[id2].accountBalance + amount;
    }

}
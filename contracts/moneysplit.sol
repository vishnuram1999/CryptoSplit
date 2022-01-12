//moneysplit
//groups, members, products, splitting money

pragma solidity ^0.8.1;

contract moneysplit {
    constructor(address _owner) public {
        owner = _owner;
    }
    struct group {
        address[] members;
        uint[] products;
        uint[] amounts;
    }
}
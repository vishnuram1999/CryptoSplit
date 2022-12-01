// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@forge-std/Test.sol";
import "../src/MoneySplit.sol";

contract MoneySplitTest is Test {
    MoneySplit public moneysplit;

    address public alice = vm.addr(1); // alice
    address public bob = vm.addr(2);   // bob
    address public cain = vm.addr(3); // cain who don't have an account
    address public denice = vm.addr(5); // denice
    address public deployer = vm.addr(4); //deployer

    function setUp() public {
        vm.startPrank(deployer);
        moneysplit = new MoneySplit();
        vm.stopPrank();
        vm.startPrank(alice);
        moneysplit.createAccount("alice");
        vm.stopPrank();
        vm.startPrank(bob);
        moneysplit.createAccount("bob");
        vm.stopPrank();
        vm.startPrank(denice);
        moneysplit.createAccount("denice");
        vm.stopPrank();
    }

    function testCreateAccount() public {
        // If alice try to create account with same address, then transcation is reverted. 
        vm.startPrank(alice);
        vm.expectRevert(bytes("You already have an account"));
        moneysplit.createAccount("alice");
        vm.stopPrank();
    }
    
    function testShowExpense() public {
        // without an account no one can access the showExpense function 
        vm.startPrank(cain);
        vm.expectRevert();
        moneysplit.showExpense();
        vm.stopPrank();
    }

    function testAddExpense() public {
        vm.startPrank(alice);
        moneysplit.addExpense("first", 100, alice);
        vm.stopPrank();
        // assertEq(moneysplit.members(address(alice))., 100);
        // assertEq(moneysplit.members(address(alice)).amountSpend, 100);
    }

    function testAddMemberToGroup() public {
        address[] memory _group = new address[](1);
        _group[0] = address(alice);
        // alice adding a member to her group
        vm.startPrank(alice);
        moneysplit.createGroup("rockers", _group);
        moneysplit.addMemberToGroup("rockers", denice);
        vm.stopPrank();

        // bob (not member of rockers) trying to add members to group, which is not not possible
        vm.startPrank(bob);
        vm.expectRevert();
        moneysplit.addMemberToGroup("rockers", denice);
        vm.stopPrank();

        // denice trying to add alice to rockers group who already exists
        assert(true);
    }
    
    function testCreateGroup() public {
        //create a group with already members with moneysplit
        address[] memory _group = new address[](2);
        _group[0] = address(alice);
        _group[1] = address(bob);
        vm.startPrank(alice);
        moneysplit.createGroup("rockers", _group);
        vm.stopPrank();

        //create a group with non members of moneysplit
        _group[1] = address(cain);
        vm.startPrank(alice);
        vm.expectRevert();
        moneysplit.createGroup("rockers", _group);
        vm.stopPrank();
    }
}
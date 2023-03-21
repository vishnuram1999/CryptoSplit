// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@forge-std/Test.sol";
import "../src/CryptoSplit.sol";

contract CryptoSplitTest is Test {
    CryptoSplit public cryptosplit;

    address public alice = vm.addr(1); // alice
    address public bob = vm.addr(2);   // bob
    address public cain = vm.addr(3); // cain who don't have an account
    address public denice = vm.addr(5); // denice
    address public deployer = vm.addr(4); //deployer

    function setUp() public {
        vm.startPrank(deployer);
        cryptosplit = new CryptoSplit();
        vm.stopPrank();
        vm.startPrank(alice);
        cryptosplit.createAccount("alice");
        vm.stopPrank();
        vm.startPrank(bob);
        cryptosplit.createAccount("bob");
        vm.stopPrank();
        vm.startPrank(denice);
        cryptosplit.createAccount("denice");
        vm.stopPrank();
    }

    function testCreateAccount() public {
        // If alice try to create account with same address, then transcation is reverted. 
        vm.startPrank(alice);
        vm.expectRevert(bytes("You already have an account"));
        cryptosplit.createAccount("alice");
        vm.stopPrank();
    }
    
    function testShowExpense() public {
        // without an account no one can access the showExpense function 
        vm.startPrank(cain);
        vm.expectRevert();
        cryptosplit.showExpense();
        vm.stopPrank();
    }

    function testAddExpense() public {
        vm.startPrank(alice);
        cryptosplit.addExpense("first", 100, alice);
        vm.stopPrank();
        (,,uint amountspend) = cryptosplit.members(address(alice));
        assertEq(amountspend, 100);
    }

    function testAddMemberToGroup() public {
        address[] memory _group = new address[](1);
        _group[0] = address(alice);
        // alice adding a member to her group
        vm.startPrank(alice);
        cryptosplit.createGroup("rockers", _group);
        cryptosplit.addMemberToGroup("rockers", denice);
        vm.stopPrank();

        // bob (not member of rockers) trying to add members to group, which is not not possible
        vm.startPrank(bob);
        vm.expectRevert();
        cryptosplit.addMemberToGroup("rockers", denice);
        vm.stopPrank();

        // denice trying to add alice to rockers group who already exists
        vm.startPrank(denice);
        vm.expectRevert(bytes("Address already exists in this group!!!"));
        cryptosplit.addMemberToGroup("rockers", alice);
        vm.stopPrank();
    }
    
    function testCreateGroup() public {
        //create a group with already members with cryptosplit
        address[] memory _group = new address[](2);
        _group[0] = address(alice);
        _group[1] = address(bob);
        vm.startPrank(alice);
        cryptosplit.createGroup("rockers", _group);
        vm.stopPrank();

        //create a group with non members of cryptosplit
        _group[1] = address(cain);
        vm.startPrank(alice);
        vm.expectRevert();
        cryptosplit.createGroup("rockers", _group);
        vm.stopPrank();
    }

    function testRemoveMemberFromGroup() public {
        // alice create a group with her and bob
        address[] memory _group = new address[](2);
        _group[0] = address(alice);
        _group[1] = address(bob);
        vm.startPrank(alice);
        cryptosplit.createGroup("rockers", _group);
        address[] memory gm = cryptosplit.showGroupMembers("rockers");
        vm.stopPrank();
        assertEq(gm.length, 2); // checking whether the length is 2 

        // remove a member from the group
        vm.startPrank(bob);
        cryptosplit.removeMemberFromGroup("rockers", alice);
        gm = cryptosplit.showGroupMembers("rockers");
        vm.stopPrank();

        assertEq(gm.length, 1); // checking whether the length is 1 because alice is removed
    }

    function testFindExpense() public {
        vm.startPrank(alice);
        cryptosplit.addExpense("peace", 100, alice);
        (,uint result) = cryptosplit.findExpense("peace");
        vm.stopPrank();
        assertEq(result, 100);

    }
}
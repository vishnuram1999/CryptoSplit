// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@forge-std/Test.sol";
import "../src/MoneySplit.sol";

contract MoneySplitTest is Test {
    MoneySplit moneysplit;

    address public alice = vm.addr(1); // alice
    address public bob = vm.addr(2);   // bob
    address public cain = vm.addr(3); // cain who don't have an account
    address public deployer = vm.addr(3); //deployer

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
        vm.expectRevert(abi.encodePacked(bytes("notMember(0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69, Not an member, Create account)")));
        moneysplit.showExpense();
        vm.stopPrank();
    }

    function testAddExpense() public {
        assert(true);
    }

    function testAddMembers() public {
        assert(true);
    }
    
    function testCreateGroup() public {
        address[] memory group;
        group[0] = cain;
        group[1] = alice;
        vm.startPrank(alice);
        moneysplit.createGroup("rockers", group);
        vm.stopPrank();
    }
}
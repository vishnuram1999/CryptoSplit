// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@forge-std/Test.sol";
import "../src/CryptoSplit.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CryptoSplitTest is Test {
    CryptoSplit public cryptosplit;
    ERC20 public usdc;

    address public alice = vm.addr(1); // alice
    address public bob = vm.addr(2);   // bob
    address public cain = vm.addr(3); // cain who don't have an account
    address public denice = vm.addr(5); // denice
    address public deployer = vm.addr(4); //deployer

    function setUp() public {
        usdc = new ERC20("Test Token", "TT"); // deploying the testToken
        vm.startPrank(deployer);
        cryptosplit = new CryptoSplit();
        vm.stopPrank();
    }
    
    function testShowExpense() public {
        // without an account no one can access the showExpense function 
        vm.startPrank(cain);
        uint256 value = cryptosplit.showExpense(); // expenses in dollars
        vm.stopPrank();
        assertEq(value, 0);
    }

    function testAddExpense() public {
        vm.startPrank(alice);
        cryptosplit.addExpense("first", 100, bob, address(usdc));
        uint256 balance = cryptosplit.showBalances(bob, address(usdc));
        vm.stopPrank();

        uint amountSpend = cryptosplit.members(address(alice));
        assertEq(amountSpend, 100);
        assertEq(balance, 100);
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
        address[] memory _group = new address[](2);
        _group[0] = address(alice);
        _group[1] = address(bob);
        vm.startPrank(alice);
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
        cryptosplit.addExpense("peace", 100, bob, address(usdc));
        (string memory name,uint result) = cryptosplit.findExpense("peace");
        vm.stopPrank();
        assertEq(result, 100);
        assertEq(name, "peace");
    }

    function testAddExpenseEqually() public {

    }

    function testPriceFeedOracle() public {

    }
}
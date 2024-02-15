// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@forge-std/Test.sol";
import "@forge-std/console2.sol";
import {CryptoSplitV2Group} from "../src/CryptoSplitV2Group.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Upgrades} from "@openzeppelin-foundry-upgrades/src/Upgrades.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./Mock/CryptoSplitV2GroupNew.sol";

contract TestToken is ERC20 {
    constructor() ERC20("Test Token", "TT") {
        _mint(msg.sender, 10_000_000);
    }
}

contract CryptoSplitV2GroupTest is Test {
    CryptoSplitV2Group public cryptosplitgroup;
    ERC20 public usdc;

    address public alice = vm.addr(1); // alice
    address public bob = vm.addr(2);   // bob
    address public cain = vm.addr(3); // cain who don't have an account
    address public denice = vm.addr(5); // denice
    address public deployer = vm.addr(4); //deployer

    address public proxy;
    address public instance1;

    function setUp() public {
        usdc = new TestToken(); // deploying the testToken
        vm.startPrank(deployer);
        proxy = Upgrades.deployUUPSProxy(
            "CryptoSplitV2Group.sol",
            abi.encodeCall(CryptoSplitV2Group.initialize, ())
        );
        instance1 = Upgrades.getImplementationAddress(proxy);
        cryptosplitgroup = CryptoSplitV2Group(proxy);
        vm.stopPrank();
        assertEq(cryptosplitgroup.owner(), deployer);
    }

    function testNotGroupMember() public {
        vm.startPrank(deployer);
        cryptosplitgroup.addAuthMember(deployer);
        cryptosplitgroup.addMember(alice);
        cryptosplitgroup.addMember(bob);
        vm.stopPrank();

        vm.startPrank(cain);
        vm.expectRevert();
        cryptosplitgroup.addExpenseEqually("first", 100, bob);
        vm.stopPrank();
    }

    function testSameExpenseName() public {
        vm.startPrank(deployer);
        cryptosplitgroup.addAuthMember(deployer);
        cryptosplitgroup.addMember(alice);
        cryptosplitgroup.addMember(bob);
        vm.stopPrank();

        vm.startPrank(alice);
        cryptosplitgroup.addExpenseEqually("first", 100, bob);
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert();
        cryptosplitgroup.addExpenseEqually("first", 100, bob);
        vm.stopPrank();
    }

    function testMemberAlreadyExist() public {
        vm.startPrank(deployer);
        cryptosplitgroup.addAuthMember(deployer);
        cryptosplitgroup.addMember(alice);
        cryptosplitgroup.addMember(bob);
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert();
        cryptosplitgroup.addMember(alice);
        vm.stopPrank();
    }

    function testAddExpenseEqually() public {
        vm.startPrank(deployer);
        cryptosplitgroup.addAuthMember(deployer);
        cryptosplitgroup.addMember(alice);
        vm.stopPrank();

        vm.startPrank(alice);
        cryptosplitgroup.addExpenseEqually("first", 100, alice);
        vm.stopPrank();
        CryptoSplitV2Group.Expense memory expense = cryptosplitgroup.getExpense("first");
        assertEq(expense.splitAmount[0], 100);
        assertEq(expense.totalAmount, 100);
        assertEq(expense.memberAddress[0], alice);

        CryptoSplitV2Group.Member memory member = cryptosplitgroup.getMember(alice);
        assertEq(member.expense, 100);

        uint256 balance = cryptosplitgroup.getBalance(alice, alice);
        assertEq(balance, 0);
    }

    function testAddExpenseUnequally() public {
        testAddExpenseEqually();
        vm.startPrank(deployer);
        cryptosplitgroup.addAuthMember(deployer);
        cryptosplitgroup.addMember(bob);
        vm.stopPrank();

        vm.startPrank(alice);
        uint256[] memory splitAmount = new uint256[](2);
        address[] memory memberAddress = new address[](2);
        splitAmount[0] = 60;
        splitAmount[1] = 40;
        memberAddress[0] = alice;
        memberAddress[1] = bob;
        cryptosplitgroup.addExpenseUnequally("second", 100, splitAmount, memberAddress, bob);
        vm.stopPrank();

        CryptoSplitV2Group.Expense memory expense = cryptosplitgroup.getExpense("second");
        assertEq(expense.splitAmount[0], 60);
        assertEq(expense.splitAmount[1], 40);
        assertEq(expense.totalAmount, 100);
        assertEq(expense.memberAddress[0], alice);
        assertEq(expense.memberAddress[1], bob);

        CryptoSplitV2Group.Member memory memberAlice = cryptosplitgroup.getMember(alice);
        assertEq(memberAlice.expense, 160);

        CryptoSplitV2Group.Member memory memberBob = cryptosplitgroup.getMember(bob);
        assertEq(memberBob.expense, 40);

        uint256 aliceBalanceToBob = cryptosplitgroup.getBalance(alice, bob);
        assertEq(aliceBalanceToBob, 60);

        uint256 bobBalanceToBob = cryptosplitgroup.getBalance(bob, alice);
        assertEq(bobBalanceToBob, 0);
    }

    function testRemoveUnequalExpense() public {
        testAddExpenseUnequally();

        vm.startPrank(alice);
        uint256[] memory splitAmount = new uint256[](2);
        address[] memory memberAddress = new address[](2);
        splitAmount[0] = 40;
        splitAmount[1] = 60;
        memberAddress[0] = alice;
        memberAddress[1] = bob;
        cryptosplitgroup.addExpenseUnequally("third", 100, splitAmount, memberAddress, bob);
        vm.stopPrank();
        CryptoSplitV2Group.Expense memory expense = cryptosplitgroup.getExpense("third");
        assertEq(expense.totalAmount, 100);

        CryptoSplitV2Group.Member memory memberAlice = cryptosplitgroup.getMember(alice);
        CryptoSplitV2Group.Member memory memberBob = cryptosplitgroup.getMember(bob);
        assertEq(memberAlice.expense, 200);
        assertEq(memberBob.expense, 100);
        
        vm.startPrank(alice);
        cryptosplitgroup.removeExpense("third");
        vm.stopPrank();
        expense = cryptosplitgroup.getExpense("third");
        assertEq(expense.totalAmount, 0);

        memberAlice = cryptosplitgroup.getMember(alice);
        memberBob = cryptosplitgroup.getMember(bob);
        assertEq(memberAlice.expense, 160);
        assertEq(memberBob.expense, 40);

        uint256 aliceBalanceToBob = cryptosplitgroup.getBalance(alice, bob);
        assertEq(aliceBalanceToBob, 60);
    }

    function testRemoveNotExpenseMember() public {
        vm.startPrank(deployer);
        cryptosplitgroup.addAuthMember(deployer);
        cryptosplitgroup.addMember(alice);
        cryptosplitgroup.addMember(bob);
        cryptosplitgroup.addMember(denice);
        vm.stopPrank();

        vm.startPrank(alice);
        uint256[] memory splitAmount = new uint256[](2);
        address[] memory memberAddress = new address[](2);
        splitAmount[0] = 40;
        splitAmount[1] = 60;
        memberAddress[0] = alice;
        memberAddress[1] = bob;
        cryptosplitgroup.addExpenseUnequally("fourth", 100, splitAmount, memberAddress, bob);
        vm.stopPrank();

        // denice can't
        vm.startPrank(denice);
        vm.expectRevert();
        cryptosplitgroup.removeExpense("fourth");
        vm.stopPrank();

        // but alice can
        vm.startPrank(alice);
        cryptosplitgroup.removeExpense("fourth");
        vm.stopPrank();
    }

    function testRemoveEqualExpense() public {
        testAddExpenseUnequally();

        vm.startPrank(alice);
        cryptosplitgroup.addExpenseEqually("fourth", 100, alice);
        vm.stopPrank();
        CryptoSplitV2Group.Expense memory expense = cryptosplitgroup.getExpense("fourth");
        assertEq(expense.totalAmount, 100);

        CryptoSplitV2Group.Member memory memberAlice = cryptosplitgroup.getMember(alice);
        CryptoSplitV2Group.Member memory memberBob = cryptosplitgroup.getMember(bob);
        assertEq(memberAlice.expense, 210);
        assertEq(memberBob.expense, 90);

        vm.startPrank(alice);
        cryptosplitgroup.removeExpense("fourth");
        vm.stopPrank();
        expense = cryptosplitgroup.getExpense("fourth");
        assertEq(expense.totalAmount, 0);

        memberAlice = cryptosplitgroup.getMember(alice);
        memberBob = cryptosplitgroup.getMember(bob);
        assertEq(memberAlice.expense, 160);
        assertEq(memberBob.expense, 40);

        uint256 aliceBalanceToBob = cryptosplitgroup.getBalance(alice, bob);
        assertEq(aliceBalanceToBob, 60);
    }

    function testRemoveExpenseDoesNotExist() public {
        vm.startPrank(deployer);
        cryptosplitgroup.addAuthMember(deployer);
        cryptosplitgroup.addMember(alice);
        cryptosplitgroup.addMember(bob);
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert();
        cryptosplitgroup.removeExpense("fifth");
        vm.stopPrank();
    }


    function test_upgrade() public {
        vm.startPrank(deployer, deployer);
        Upgrades.upgradeProxy(
            proxy,
            "CryptoSplitV2GroupNew.sol",
            ""
        );
        address instance2 = Upgrades.getImplementationAddress(proxy);
        CryptoSplitV2GroupNew newcontract = CryptoSplitV2GroupNew(instance2);
        bool flag = newcontract.isUpdated();
        assertEq(flag, true);
        vm.stopPrank();
        assertFalse(instance1 == instance2);
    }
}
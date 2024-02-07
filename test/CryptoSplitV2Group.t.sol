// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@forge-std/Test.sol";
import "../src/CryptoSplitV2Group.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Upgrades} from "@openzeppelin-foundry-upgrades/src/Upgrades.sol";

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

    function setUp() public {
        usdc = new TestToken(); // deploying the testToken
        vm.startPrank(deployer);
        address proxy = Upgrades.deployUUPSProxy(
            "CryptoSplitV2Group.sol",
            abi.encodeCall(CryptoSplitV2Group.initialize, ())
        );
        cryptosplitgroup = CryptoSplitV2Group(proxy);
        vm.stopPrank();
        assertEq(cryptosplitgroup.owner(), deployer);
    }

    function testAddExpense() public {
        vm.startPrank(deployer);
        cryptosplitgroup.addAuthMember(deployer);
        cryptosplitgroup.addMember(alice);
        vm.stopPrank();

        vm.startPrank(alice);
        cryptosplitgroup.addExpenseEqually("first", 100);
        vm.stopPrank();
    }
}
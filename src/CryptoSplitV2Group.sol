//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "./interfaces/ICryptoSplitV2Group.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @custom:oz-upgrades
contract CryptoSplitV2Group is
    Initializable,
    AccessControlUpgradeable,
    Ownable2StepUpgradeable,
    UUPSUpgradeable,
    ICryptoSplitV2Group
{
    event AddedGroupMember(address);
    event RemovedGroupMember(address);

    struct Member {
        address memberAddress;
        uint256 expense;
    }

    struct Expense {
        uint256 totalAmount;
        uint256[] splitAmount;
        address[] memberAddress;
        address paidAddress;
        // address tokenAddress;
    }

    Member[] public members;
    mapping(string expenseName => Expense) public expenses;
    mapping(address => mapping(address => uint256)) public balances;

    uint256[47] private __gap;

    function initialize() external virtual initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __AccessControl_init();
    }

    function addMember(
        address memberAddress
    ) external onlyRole(bytes32("AuthMember")) {
        require(!hasRole(bytes32('GroupMember'), memberAddress), "Already a group member");
        _grantRole(bytes32("GroupMember"), memberAddress);
        Member memory initMember;
        initMember.expense = 0;
        initMember.memberAddress = memberAddress;
        members.push(initMember);
        emit AddedGroupMember(memberAddress);
    }

    function removeMember(
        address memberAddress
    ) external onlyRole(bytes32("AuthMember")) {
        _revokeRole(bytes32("GroupMember"), memberAddress);
        emit RemovedGroupMember(memberAddress);
    }

    function addAuthMember(address memberAddress) external onlyOwner {
        _grantRole(bytes32("AuthMember"), memberAddress);
    }

    function removeAuthMember(address memberAddress) external onlyOwner {
        _revokeRole(bytes32("AuthMember"), memberAddress);
    }

    function addExpenseEqually(
        string memory expenseName,
        uint256 totalAmount,
        address paidAddress
    ) external onlyRole(bytes32("GroupMember")) {
        require(hasRole(bytes32('GroupMember'), paidAddress), "Not a group member");
        require(totalAmount != 0, "Amount can't be zero");
        require(
            expenses[expenseName].totalAmount == 0,
            "Expense name already exists"
        );
        _grantRole(keccak256(abi.encode(bytes32('ExpenseMember'), bytes(expenseName))), paidAddress);
        uint256 totalMembers = members.length;
        (bool success, uint256 individualAmount) = Math.tryDiv(
            totalAmount,
            totalMembers
        );
        require(success, "Operation failed");

        uint256[] memory splitAmount = new uint256[](totalMembers);
        address[] memory memberAddress = new address[](totalMembers);
        
        for (uint256 i; i < totalMembers; i++) {
            members[i].expense += individualAmount;
            splitAmount[i] = individualAmount;
            _grantRole(keccak256(abi.encode(bytes32('ExpenseMember'), bytes(expenseName))), members[i].memberAddress);
            memberAddress[i] = members[i].memberAddress;
            if (members[i].memberAddress != paidAddress) {
                balances[members[i].memberAddress][paidAddress] += individualAmount;
            }
        }

        expenses[expenseName].totalAmount = totalAmount;
        expenses[expenseName].memberAddress = memberAddress;
        expenses[expenseName].splitAmount = splitAmount;
        expenses[expenseName].paidAddress = paidAddress;
    }

    function addExpenseUnequally(
        string memory expenseName,
        uint256 totalAmount,
        uint256[] calldata splitAmount,
        address[] calldata memberAddress,
        address paidAddress
    ) external onlyRole(bytes32("GroupMember")) {
        require(hasRole(bytes32('GroupMember'), paidAddress), "Not a group member");
        require(
            splitAmount.length == memberAddress.length,
            "Array length mismatch"
        );
        require(totalAmount != 0, "Amount can't be zero");
        require(
            expenses[expenseName].totalAmount == 0,
            "Expense name already exists"
        );
        uint256 totalMembers = members.length;
        uint256 totalSplitAmount;
        for (uint256 i; i < splitAmount.length; i++) {
            totalSplitAmount += splitAmount[i];
        }
        require(totalSplitAmount == totalAmount, "Split amount mismatch");

        _grantRole(keccak256(abi.encode(bytes32('ExpenseMember'), bytes(expenseName))), paidAddress);
        
        for (uint256 i; i < totalMembers; i++) {
            for (uint256 j; j < memberAddress.length; j++) {
                if (members[i].memberAddress == memberAddress[j]) {
                    _grantRole(keccak256(abi.encode(bytes32('ExpenseMember'), bytes(expenseName))), memberAddress[j]);
                    members[i].expense += splitAmount[j];
                    if (memberAddress[j] != paidAddress) {
                        balances[memberAddress[j]][paidAddress] += splitAmount[j];
                    }
                }
            }
        }

        expenses[expenseName].totalAmount = totalAmount;
        expenses[expenseName].splitAmount = splitAmount;
        expenses[expenseName].memberAddress = memberAddress;
        expenses[expenseName].paidAddress = paidAddress;
    }

    function removeExpense(
        string memory expenseName
    ) external onlyRole(bytes32("GroupMember")) {
        require(
            expenses[expenseName].totalAmount != 0,
            "Expense name doesn't exist"
        );
        require(hasRole(keccak256(abi.encode(bytes32('ExpenseMember'), bytes(expenseName))), msg.sender), "Not a part of expense");

        for (uint256 i; i < members.length; i++) {
            for (uint256 j; j < expenses[expenseName].memberAddress.length; j++) {
                if (members[i].memberAddress == expenses[expenseName].memberAddress[j]) {
                    members[i].expense -= expenses[expenseName].splitAmount[j];
                    if (expenses[expenseName].memberAddress[j] != expenses[expenseName].paidAddress) {
                        balances[members[i].memberAddress][expenses[expenseName].paidAddress] -= expenses[expenseName].splitAmount[j];
                    }
                }
            }
        }
        delete expenses[expenseName];
    }

    function getExpense(string memory expenseName)
        external
        view
        returns (Expense memory)
    {
        return expenses[expenseName];
    }

    function getMember(address memberAddress)
        external
        view
        returns (Member memory)
    {
        for (uint256 i; i < members.length; i++) {
            if (members[i].memberAddress == memberAddress) {
                return members[i];
            }
        }
        return Member(address(0), 0);
    }

    function getBalance(address memberAddress, address paidAddress)
        external
        view
        returns (uint256)
    {
        return balances[memberAddress][paidAddress];
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../../src/interfaces/ICryptoSplitV2Group.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @custom:oz-upgrades-from CryptoSplitV2Group
contract CryptoSplitV2GroupNew is
    Initializable,
    AccessControlUpgradeable,
    Ownable2StepUpgradeable,
    UUPSUpgradeable,
    ICryptoSplitV2Group
{
    event AddedGroupMember(address);
    event RemovedGroupMember(address);

    struct Member {
        uint256 expense;
    }

    Member[] private members;

    uint256[49] private __gap;

    function initialize() external virtual initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __AccessControl_init();
    }

    function addMember(
        address memberAddress
    ) external onlyRole(bytes32("AuthMember")) {
        _grantRole(bytes32("GroupMember"), memberAddress);
        Member memory initMember;
        initMember.expense = 0;
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
        uint256 totalAmount
    ) external onlyRole(bytes32("GroupMember")) {
        require(totalAmount != 0, "Amount can't be zero");
        uint256 totalMembers = members.length;
        (bool success, uint256 individualAmount) = Math.tryDiv(
            totalAmount,
            totalMembers
        );
        require(success, "Operation failed");
        for (uint256 i; i < totalMembers; i++) {
            members[i].expense += individualAmount;
        }
    }

    function addExpenseUnequally(
        string memory expenseName,
        uint256 totalAmount,
        uint256[] calldata splitAmount
    ) external onlyRole(bytes32("GroupMember")) {}

    function removeExpense(
        string memory expenseName
    ) external onlyRole(bytes32("GroupMember")) {}

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}

    function isUpdated() public pure returns(bool) {
        return true;
    }
}

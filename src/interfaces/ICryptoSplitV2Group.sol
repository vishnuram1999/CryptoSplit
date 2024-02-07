//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
interface ICryptoSplitV2Group {
    function addMember(address) external;

    function removeMember(address) external;

    function addAuthMember(address) external;

    function removeAuthMember(address) external;

    function addExpenseEqually(string memory, uint256) external;

    function addExpenseUnequally() external;

    function removeExpense(string memory) external;

}
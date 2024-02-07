//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "./interfaces/ICryptoSplitV2GroupFactory.sol";
import "./CryptoSplitV2Group.sol";

contract CryptoSplitV2GroupFactory is ICryptoSplitV2GroupFactory {
    CryptoSplitV2Group[] public grouplist;
    function createGroup() external returns(address) {
        CryptoSplitV2Group groupAddress = new CryptoSplitV2Group();
        grouplist.push(groupAddress);
        return address(groupAddress);
    }
}
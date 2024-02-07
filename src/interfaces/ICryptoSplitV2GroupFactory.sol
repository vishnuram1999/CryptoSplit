//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
interface ICryptoSplitV2GroupFactory {
    function createGroup() external returns(address);
}
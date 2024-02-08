//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "./interfaces/ICryptoSplitV2GroupFactory.sol";
import "./CryptoSplitV2Group.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

// TODO: use create2 to deploy new contracts

/// @custom:oz-upgrades
contract CryptoSplitV2GroupFactory is
    ICryptoSplitV2GroupFactory,
    UUPSUpgradeable
{
    CryptoSplitV2Group[] public grouplist;

    uint256[49] private __gap;

    function createGroup() external returns (address) {
        CryptoSplitV2Group groupAddress = new CryptoSplitV2Group();
        grouplist.push(groupAddress);
        return address(groupAddress);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}
}
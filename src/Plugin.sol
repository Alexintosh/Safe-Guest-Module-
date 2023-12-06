// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {BasePluginWithEventMetadata, PluginMetadata} from "./Base.sol";
import {ISafe} from "@safe/interfaces/Accounts.sol";
import {ISafeProtocolManager} from "@safe/interfaces/Manager.sol";
import {SafeTransaction, SafeProtocolAction} from "@safe/DataTypes.sol";
import {Enum} from "@safe/common/Enum.sol";

contract GuestSigner is BasePluginWithEventMetadata {

    uint256 public timestamp;
    address tempSigner;
    //ISafe public immutable safe;

    constructor()
        BasePluginWithEventMetadata(
            PluginMetadata({
                name: "GuestSigner",
                version: "0.0.1",
                requiresRootAccess: false,
                iconUrl: "",
                appUrl: ""
            })
    ){}

    function setGuest(address guest, uint untilTimestamp) external {
        //require(safe.isOwner(msg.sender), "!owner");
        require(block.timestamp >= untilTimestamp);
        require(guest != address(0), "0 add");

        timestamp = timestamp;
        tempSigner = guest;
    }

    function executeFromGuest (
        address safe,
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) external {
        require(timestamp <= block.timestamp, 'too late');
        require(msg.sender == tempSigner, 'not my guest');
        require(ISafe(safe).execTransactionFromModule(payable(to), value, data, uint8(operation)), "!execute");
    }
}

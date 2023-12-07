// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {BasePluginWithEventMetadata, PluginMetadata} from "./Base.sol";
import {IAvatar} from "@src/IAvatar.sol";
import {ISafeProtocolManager} from "@safe/interfaces/Manager.sol";
import {SafeTransaction, SafeProtocolAction} from "@safe/DataTypes.sol";
import {Enum} from "@safe/common/Enum.sol";

contract GuestSigner is BasePluginWithEventMetadata {

    uint256 public timestamp;
    address public tempSigner;
    IAvatar public immutable safe;

    constructor(address _safe)
        BasePluginWithEventMetadata(
            PluginMetadata({
                name: "GuestSigner",
                version: "0.0.1",
                requiresRootAccess: false,
                iconUrl: "",
                appUrl: ""
            })
    ){
        safe = IAvatar(_safe);
    }

    function setGuest(address guest, uint untilTimestamp) external {
        require(msg.sender == address(safe), "!safe");
        require(block.timestamp <= untilTimestamp, "!time");
        require(guest != address(0), "0 add");

        timestamp = untilTimestamp;
        tempSigner = guest;
    }

    function executeFromGuest (
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) external {
        require(timestamp >= block.timestamp, 'too late');
        require(msg.sender == tempSigner, 'not my guest');
        require(IAvatar(safe).execTransactionFromModule(payable(to), value, data, operation), "!execute");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {SafeProtocolRegistry} from "@safe/SafeProtocolRegistry.sol";
import {SafeProtocolManager} from "@safe/SafeProtocolManager.sol";
import {GuestSigner} from "@src/Plugin.sol";

contract DeployContracts is Script {
    function run(address owner) public returns (GuestSigner, SafeProtocolManager, SafeProtocolRegistry) {
        SafeProtocolRegistry registry = new SafeProtocolRegistry(owner);
        SafeProtocolManager manager = new SafeProtocolManager(owner, address(registry));
        GuestSigner plugin = new GuestSigner(address(0));
        return (plugin, manager, registry);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {GuestSigner} from "@src/Plugin.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@safe/Safe.sol";
import "@safe/proxies/SafeProxy.sol";
import {IAvatar} from "@src/IAvatar.sol";
import {Enum} from "@safe/common/Enum.sol";

contract MockToken is ERC20("USDBRR", "USDBRR") {
    function mint(address to, uint256 quantity) external returns (bool) {
        _mint(to, quantity);
        return true;
    }

    function burn(address from, uint256 quantity) external returns (bool) {
        _burn(from, quantity);
        return true;
    }
}


contract GuestModTest is Test {
    GuestSigner public guestMod;
    address public safeImplementation;
    Safe public safe;
    MockToken public mockToken;

    // Owners
    address own1 = address(0x69);
    address own2 = address(0x420);

    // Operators with roles
    address guest = address(0x66);

    function setUp() public {
        safeImplementation = address(new Safe());
        safe = Safe(payable(address(new SafeProxy(safeImplementation))));
        mockToken = new MockToken();

        mockToken.mint(address(safe), 1000000 ether);

        address[] memory owners = new address[](1);
        owners[0] = own1;

        /**
        * @param _owners List of Safe owners.
        * @param _threshold Number of required confirmations for a Safe transaction.
        * @param to Contract address for optional delegate call.
        * @param data Data payload for optional delegate call.
        * @param fallbackHandler Handler for fallback calls to this contract
        * @param paymentToken Token that should be used for the payment (0 is ETH)
        * @param payment Value that should be paid
        * @param paymentReceiver Address that should receive the payment (or 0 if tx.origin)
        */
        safe.setup(
            owners,
            1,
            address(0), 
            "",
            address(0),
            address(0),
            0,
            payable(address(0))
        );
        
        // Creating  module
        guestMod = new GuestSigner(address(safe));

        // Adding  module
        execCall(
            owners[0],
            address(safe),
            abi.encodeWithSelector(IAvatar.enableModule.selector, address(guestMod))
        );
    }

    function testisModuleEnabled() public {
        bool enabled = safe.isModuleEnabled(address(guestMod));
        assertEq(enabled, true);
    }

    function testFuzz_AddingGuestWorks(uint256 beMyGuest) public {
        // Add guest
        execCall(
            own1,
            address(guestMod),
            abi.encodeWithSelector(GuestSigner.setGuest.selector, guest, (block.timestamp + 10 days))
        );

        console.log("guest", guestMod.tempSigner());
        assertEq(guestMod.tempSigner(), guest);
    }

    function testFuzz_guestCannotDoAnythingBeforePermission(uint256 beMyGuest) public {
        //Executing as guest
        vm.prank(guest);
        vm.expectRevert("too late");
        guestMod.executeFromGuest(
            address(mockToken), 
            0, 
            abi.encodeWithSelector(IERC20.approve.selector, guest, 1 ether), 
            Enum.Operation.Call
        );
    }

    function testFuzz_canDoAnythingAfterPermission(uint256 beMyGuest) public {
        //Setting guest
        execCall(
            own1,
            address(guestMod),
            abi.encodeWithSelector(GuestSigner.setGuest.selector, guest, (block.timestamp + 10 days))
        );

        console.log("after", block.timestamp);
        console.log("from module", guestMod.timestamp());

        //Executing as guest
        vm.prank(guest);
        guestMod.executeFromGuest(
            address(mockToken), 
            0, 
            abi.encodeWithSelector(IERC20.approve.selector, guest, 1 ether), 
            Enum.Operation.Call
        );
    }

    function testFuzz_cantDoAnythingAfterTimestampExpired(uint256 beMyGuest) public {
        //Setting guest
        vm.warp(0);

        execCall(
            own1,
            address(guestMod),
            abi.encodeWithSelector(GuestSigner.setGuest.selector, guest, (block.timestamp + 1 hours))
        );

        //Going the FUTOOOR
        vm.warp((block.timestamp + 1 days));


        //Executing as guest
        vm.prank(guest);
        vm.expectRevert("too late");
        guestMod.executeFromGuest(
            address(mockToken), 
            0, 
            abi.encodeWithSelector(IERC20.approve.selector, guest, 1 ether), 
            Enum.Operation.Call
        );
    }

    function testFuzz_setGuestRevertsIfNotSafeCalling(uint256 beMyGuest) public {
        vm.expectRevert("!safe");
        guestMod.setGuest(guest, (block.timestamp + 10 days));
    }

    function execCall(
        address signer, 
        address to, 
        bytes memory data
    ) internal {
        vm.prank(signer);
        safe.execTransaction(
            to,
            0,
            data,
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            getSig(signer)
        );
    }

    function getSig(address signer) internal returns(bytes memory) {
        return abi.encodePacked(
            uint256(uint160(signer)),
            uint256(0),
            uint8(1)
        );
    }
}
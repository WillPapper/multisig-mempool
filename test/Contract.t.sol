// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract ContractTest is Test {
    function setUp() public {}

    function testExample() public {
        assertTrue(true);
    }

    function testMainnetFork() public {
        assertTrue(
            address(0x000000000000000000000000000000000000dEaD).balance > 0
        );
    }
}

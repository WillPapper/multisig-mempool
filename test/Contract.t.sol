// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract ContractTest is Test {
    function setUp() public {}

    function testExample() public {
        assertTrue(true);
    }

    function testMainnetForkBalance() public {
        assertTrue(
            address(0x000000000000000000000000000000000000dEaD).balance > 0
        );
    }

    function testMainnetForkContract() public {
        // Assert that 0xdEaD is not a contract
        assertTrue(
            !isContract(address(0x000000000000000000000000000000000000dEaD))
        );

        // Assert that the ConstitutionDAO Gnosis Safe is a contract
        assertTrue(
            isContract(address(0xb1C95AC257029D11F3f64ac67b2307A426699322))
        );
    }

    // From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/5fbf494511fd522b931f7f92e2df87d671ea8b0b/contracts/utils/Address.sol#L36
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }
}

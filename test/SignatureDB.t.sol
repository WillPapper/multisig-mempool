// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../lib/forge-std/src/Test.sol";
import {SignatureDB} from "../src/SignatureDB.sol";
import {GnosisSafe} from "../lib/safe-contracts/contracts/GnosisSafe.sol";
import {GnosisSafeProxyFactory} from "../lib/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";

contract SignatureDBTest is Test {
    SignatureDB signatureDB;

    function setUp() public {
        console.logString("Setting up");
        signatureDB = new SignatureDB();
    }

    function testAddSignatures() public {}

    function testCreateGnosisSafe() public {
        createProxyWithNonce();
    }

    function createProxyWithNonce() public {
        // Create a Safe from the 1.3.0 version of the Gnosis Safe contract.
        GnosisSafeProxyFactory proxyFactory = GnosisSafeProxyFactory(
            // Address of Gnosis Safe: Proxy Factory 1.3.0
            0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2
        );

        address[] memory owners = new address[](3);

        // Initialize owners with private keys of 1, 2, and 3
        owners[0] = vm.addr(1);
        owners[1] = vm.addr(2);
        owners[2] = vm.addr(3);

        // Data encoding found via https://ethereum.stackexchange.com/questions/121854/how-to-encode-initializer-in-gnosis-safe-proxy-contract and https://github.com/5afe/safe-factories/blob/master/contracts/Safe_1_1_1_Factory.sol#L28
        bytes memory proxyInitData = abi.encodeWithSignature(
            "setup()",
            owners,
            3,
            address(0x0),
            new bytes(0),
            address(0x0),
            address(0x0),
            0,
            address(0x0)
        );
        proxyFactory.createProxyWithNonce(
            // Address of Gnosis Safe: Singleton 1.3.0
            0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552,
            proxyInitData,
            1
        );
    }
}

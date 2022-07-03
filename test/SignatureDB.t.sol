// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../lib/forge-std/src/Test.sol";
import {GnosisSafe} from "../lib/safe-contracts/contracts/GnosisSafe.sol";
import {GnosisSafeProxyFactory} from "../lib/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";

contract SignatureDBTest is Test {
    function setUp() public {}

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
        owners[0] = address(0x1);
        owners[1] = address(0x2);
        owners[2] = address(0x3);

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

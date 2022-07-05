// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../lib/forge-std/src/Test.sol";
import {SignatureDB} from "../src/SignatureDB.sol";
import {GnosisSafe} from "../lib/safe-contracts/contracts/GnosisSafe.sol";
import {GnosisSafeProxy} from "../lib/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";
import {GnosisSafeProxyFactory} from "../lib/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";

contract SignatureDBTest is Test {
    SignatureDB signatureDB;
    GnosisSafeProxy gnosisSafe;
    address[] owners = new address[](3);

    function setUp() public {
        console.logString("Setting up");
        signatureDB = new SignatureDB();
        createProxy();
    }

    function testAddSignature() public {
        address alice = owners[0];
        bytes32 dataHash = keccak256("Signed by Alice");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, dataHash);
        address signer = ecrecover(dataHash, v, r, s);
        assertEq(alice, signer); // [PASS]
        // Can combine into a single 65-byte signature. See https://medium.com/mycrypto/the-magic-of-digital-signatures-on-ethereum-98fe184dc9c7
        bytes memory signature = bytes.concat(r, s, abi.encodePacked(v));
        // bytes[] memory signatures = new bytes[];
        // signatures[0] = abi.encodePacked(signature);
        console.log("Adding signature");
        signatureDB.addSignatures(address(gnosisSafe), dataHash, signature);
        console.log("Signature added");
        assertTrue(
            signatureDB
                .signaturesForDataHash(address(gnosisSafe), alice, dataHash)
                .length !=
                0 &&
                // Comparing hashes is a quick hack to avoid needing to loop
                // through them one by one:
                // https://ethereum.stackexchange.com/questions/99340/error-comparing-two-bytes-memory
                // TODO: Add a function that loops through both bytes and checks
                // one by one, after comparing the length
                keccak256(
                    signatureDB.signaturesForDataHash(
                        address(gnosisSafe),
                        alice,
                        dataHash
                    )
                ) ==
                keccak256(signature)
        );
    }

    function testCreateGnosisSafe() public {
        createProxyWithNonce();
    }

    function createProxy() public {
        // Create a Safe from the 1.3.0 version of the Gnosis Safe contract.
        GnosisSafeProxyFactory proxyFactory = GnosisSafeProxyFactory(
            // Address of Gnosis Safe: Proxy Factory 1.3.0
            0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2
        );

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
        gnosisSafe = proxyFactory.createProxy(
            // Address of Gnosis Safe: Singleton 1.3.0
            0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552,
            proxyInitData
        );
    }

    function createProxyWithNonce() public {
        // Create a Safe from the 1.3.0 version of the Gnosis Safe contract.
        GnosisSafeProxyFactory proxyFactory = GnosisSafeProxyFactory(
            // Address of Gnosis Safe: Proxy Factory 1.3.0
            0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2
        );

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
        gnosisSafe = proxyFactory.createProxyWithNonce(
            // Address of Gnosis Safe: Singleton 1.3.0
            0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552,
            proxyInitData,
            1
        );
    }
}

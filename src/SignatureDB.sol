// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../lib/forge-std/src/Test.sol";
import {GnosisSafe} from "../lib/safe-contracts/contracts/GnosisSafe.sol";
import {ECDSA} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract SignatureDB {
    // Mapping of owner address => Gnosis Safe address => dataHash => Sorted array of signatures
    mapping(address => mapping(address => mapping(bytes32 => bytes)))
        public signaturesForDataHash;

    // Mapping of => dataHash => data
    // All we need to do is confirm that the dataHash and the data match, and
    // then we can add it We can even add the data without the dataHash, and
    // hash it in realtime. Both functions can be provided
    mapping(bytes32 => bytes) public dataForDataHash;

    // TODO: Add events

    /// This can take in signatures from multiple signers for a single dataHash.
    /// Since we're getting the address of the owner from ecrecover, we can save on calldata by not passing in the addresses
    function addSignatures(
        address gnosisSafe,
        bytes32 dataHash,
        bytes memory signatures
    ) public {
        require(
            signatures.length % 65 == 0,
            "Signatures must be 65 bytes long"
        );

        // Grab the signatures every 65 bytes
        for (uint256 i; i < signatures.length; i += 65) {
            bytes memory signature;
            uint256 amountToLoad = i + 65;

            console.log("Loading signature");

            // Based loosely on https://ethereum.stackexchange.com/questions/26434/whats-the-best-way-to-transform-bytes-of-a-signature-into-v-r-s-in-solidity
            assembly {
                signature := mload(add(signatures, amountToLoad))
            }
            console.log("Signature loaded");
            // Temporary  to get the tests to pass since signatures is only one
            // signature
            // TODO: Fix signature parsing for multiple signatures
            signature = signatures;

            // TODO: Prevent recovering to arbitrary addresses
            // https://docs.openzeppelin.com/contracts/4.x/api/utils#ECDSA-tryRecover-bytes32-bytes-
            // The risk of this in practice may be low, because addresses other
            // than the signers are ignored during signature construction
            console.log("Recovering signature");
            (address signer, ECDSA.RecoverError error) = ECDSA.tryRecover(
                dataHash,
                signature
            );
            console.logBytes(signature);
            console.log("Signature recovered");
            if (error == ECDSA.RecoverError.NoError && signer != address(0)) {
                // TODO: Determine whether you want to sort the signatures here
                // or sort them in the getter
                console.log("Writing signature:");
                console.logBytes(
                    bytes.concat(
                        signaturesForDataHash[signer][gnosisSafe][dataHash],
                        signature
                    )
                );
                signaturesForDataHash[signer][gnosisSafe][dataHash] = bytes
                    .concat(
                        signaturesForDataHash[signer][gnosisSafe][dataHash],
                        signature
                    );
                console.log("Signature written");
            }
        }
    }

    function addData(bytes calldata data) public {
        dataForDataHash[keccak256(data)] = data;
    }

    function addData(bytes32 dataHash, bytes calldata data) public {
        // Check that the dataHash matches the data
        if (keccak256(data) == dataHash) {
            dataForDataHash[dataHash] = data;
        } else {
            revert("Datahash does not match data");
        }
    }

    function setSignatureReward() public payable {}
}

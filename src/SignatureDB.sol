// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {GnosisSafe} from "../lib/safe-contracts/contracts/GnosisSafe.sol";
import {ECDSA} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract SignatureDB {
    // Mapping of owner address => Gnosis Safe address => dataHash => Sorted array of signatures
    mapping(address => mapping(address => mapping(bytes32 => bytes[])))
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
        bytes[] calldata signatures
    ) public {
        for (uint256 i; i < signatures.length; ) {
            // TODO: Prevent recovering to arbitrary addresses
            // https://docs.openzeppelin.com/contracts/4.x/api/utils#ECDSA-tryRecover-bytes32-bytes-
            // The risk of this in practice may be low, because addresses other
            // than the signers are ignored during signature construction
            (address signer, ECDSA.RecoverError error) = ECDSA.tryRecover(
                dataHash,
                signatures[i]
            );
            if (error == ECDSA.RecoverError.NoError && signer != address(0)) {
                // TODO: Determine whether you want to sort the signatures here
                // or sort them in the getter
                signaturesForDataHash[signer][gnosisSafe][dataHash].push(
                    signatures[i]
                );
            }

            // We can use unchecked here since it's not possible in practice for
            // the array of signatures to overflow
            unchecked {
                ++i;
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

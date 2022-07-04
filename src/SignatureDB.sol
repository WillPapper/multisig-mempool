// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {GnosisSafe} from "../lib/safe-contracts/contracts/GnosisSafe.sol";

contract SignatureDB {
    // Mapping of Gnosis Safe address => dataHash => Transaction
    mapping(address => mapping(bytes32 => Transaction)) transactionsForGnosisSafe;

    // Mapping of Gnosis Safe address => owner => owner status of the Gnosis Safe
    // A mapping is used so that we can look up owners in O(1) time when adding
    // signatures. This allows for cheap writes.
    mapping(address => mapping(address => bool)) ownersForGnosisSafe;
    // Mapping of Gnosis Safe address => index => owner
    // We simultaneously maintain an index so that we can loop through the list
    // of owners. This index is sorted for the ease of constructing valid packed
    // signatures for Gnosis, because Gnosis's execTransaction() function also
    // requires sorting.
    // Separating the owners and the index is broadly inspired by
    // ERC721Enumerable.
    mapping(address => mapping(uint256 => address)) ownerIndexForGnosisSafe;

    // We don't need the dataHash because that is used as the key in the mapping.
    struct Transaction {
        bytes data;
        bytes signatures;
    }

    // TODO: Add events

    function initializeTransaction(
        address gnosisSafe,
        bytes32 dataHash,
        bytes calldata data,
        bytes calldata signatures
    ) public {
        checkSignaturesGnosis(gnosisSafe, dataHash, data, signatures);

        // Once we have checked the signatures, we can store the initial transaction
        Transaction memory transaction = Transaction(data, signatures);
        transactionsForGnosisSafe[gnosisSafe][dataHash] = transaction;
    }

    /// @notice You can add one or multiple signatures via concatenated bytes
    /// @dev The only requirement for `signatures` is that it is greater than
    /// the previous bytes of signatures. This means that the set of signers
    /// could change. So this does not strictly always add signatures. If the
    /// new set of signatures is greater than the previous set of signatures but
    /// has different signers, the signers from the previous set that are not
    /// represented in the new set will be removed. What this does guarantee,
    /// however, is that calling `addSignatures()` will always ensure that a
    /// transaction is closer to execution than before.
    /// TODO: Handle signature insertion on-chain, which ensure that signatures
    /// are always increasing.
    function addSignatures(
        address gnosisSafe,
        bytes32 dataHash,
        bytes calldata signatures
    ) public {
        Transaction memory transaction = transactionsForGnosisSafe[gnosisSafe][
            dataHash
        ];

        // Check whether the transaction has been initialized.
        // We can't initialize the transaction for the user here because we
        // don't have the data available. We avoid passing in the data to save
        // on calldata costs, because the data is only necessary when a
        // signature is initialized and then afterward is kept in storage
        require(
            transaction.signatures.length != 0,
            "Transaction must be initialized"
        );

        // Place the new signatures at the start of the concatenated bytes
        // This ensures that any failure in the new signatures will
        // short-circuit. As a result, gas will not be wasted checking the old
        // signatures.
        // TODO: You'll need to deconstruct, sort, and insert these signatures
        // on-chain to ensure that previous signatures are never removed
        bytes memory signaturesConcat = bytes.concat(
            signatures,
            transaction.signatures
        );

        // Check that the new data is valid
        // TODO: Confirm whether you can check only `signatures` for the new
        // signatures, without needing to check all of `signaturesConcat`. You'd
        // need to manually check whether the signatures meet the transaction
        // threshold, which as a benefit also allows you to cut off signing when
        // the transaction threshold is reached.
        checkSignaturesGnosis(
            gnosisSafe,
            dataHash,
            transaction.data,
            signaturesConcat
        );

        transactionsForGnosisSafe[gnosisSafe][dataHash]
            .signatures = signaturesConcat;
    }

    function checkSignaturesGnosis(
        address gnosisSafe,
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures
    ) public view {
        // Check that the initial transaction is valid
        // This will fail within GnosisSafe.checkNSignatures() if any signature is invalid
        GnosisSafe(payable(gnosisSafe)).checkSignatures(
            dataHash,
            data,
            signatures
        );
    }

    function setSignatureReward() public payable {}
}

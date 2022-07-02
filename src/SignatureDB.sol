// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {GnosisSafe} from "../lib/safe-contracts/contracts/GnosisSafe.sol";

contract SignatureDB {
    // Mapping of Gnosis Safe address => dataHash => Transaction
    mapping(address => mapping(bytes32 => Transaction)) transactionsForGnosisSafe;

    // We don't need the dataHash because that is used as the key in the mapping.
    struct Transaction {
        bytes data;
        bytes signatures;
    }

    uint256 public nonce;

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

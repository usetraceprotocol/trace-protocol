// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Shared storage layout for TraceAttestation. Kept in a dedicated
///         file so upgrades preserve slot ordering.
library AttestationStorage {
    /// @notice Verdict classification produced by the off-chain classifier.
    enum VerdictType {
        Unknown,    // 0 — sentinel, never persisted
        Autonomous, // 1
        Hybrid,     // 2
        Human       // 3
    }

    /// @notice Single attestation record. Packed for storage efficiency.
    struct Attestation {
        address authority;
        VerdictType verdict;
        uint16 confidence;
        uint32 signalCount;
        uint32 transactionCount;
        uint64 createdAt;
        uint64 updatedAt;
        uint64 blockNumber;
        bytes8 modelVersion;
        bytes32 evidenceHash;
        bool frozen;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Read-only view of the TraceAttestation registry consumed by the hook.
///         The hook never writes to the registry — writes are submitted by the
///         off-chain classifier through the canonical attester key.
interface ITraceAttestation {
    enum VerdictType {
        UNKNOWN,
        AUTONOMOUS,
        HYBRID,
        HUMAN
    }

    struct Verdict {
        VerdictType verdict;
        uint16 confidenceBps;
        bytes8 modelVersion;
        bytes32 evidenceHash;
        uint64 timestamp;
    }

    function verdictOf(address agent) external view returns (Verdict memory);

    function hasVerdict(address agent) external view returns (bool);
}

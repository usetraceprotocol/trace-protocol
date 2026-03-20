// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Custom errors for TraceAttestation. Cheaper than require strings.
library Errors {
    /// @notice Caller is not the authorised attester.
    error NotAuthorized();

    /// @notice Verdict byte does not map to a known VerdictType.
    error InvalidVerdictType(uint8 raw);

    /// @notice Confidence value exceeds 10000 (basis-point scale, 10000 = 100%).
    error ConfidenceOutOfRange(uint16 confidence);

    /// @notice Attestation requires at least one observed signal.
    error InsufficientSignals();

    /// @notice No attestation exists for the given agent.
    error AttestationNotFound(address agent);

    /// @notice Attempted to update an attestation that has been frozen.
    error AttestationFrozen(address agent);

    /// @notice Attester rotation requires the new attester to be non-zero.
    error ZeroAddressAttester();
}

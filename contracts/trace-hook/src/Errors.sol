// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Errors emitted by TraceHook. Kept in a separate file so off-chain
///         decoders can ABI-lift them without pulling in the full hook bytecode.
library Errors {
    /// @notice Hook entrypoint was called by something other than the pool
    ///         manager configured at deployment.
    error NotPoolManager(address caller);

    /// @notice The configured scanner-funding sink is the zero address.
    error ScannerFundingNotSet();

    /// @notice The configured trace-attestation registry is the zero address.
    error AttestationRegistryNotSet();

    /// @notice Fee in basis points is out of range. Hard cap is 100 bps (1%).
    error ScannerFeeOutOfRange(uint16 requestedBps, uint16 maxBps);

    /// @notice Hook was invoked with a pool key whose `hooks` field does not
    ///         match this contract — most likely a misconfigured pool.
    error PoolKeyMismatch(address expected, address received);
}

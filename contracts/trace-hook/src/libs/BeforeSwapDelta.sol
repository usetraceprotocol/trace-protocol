// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Packed (int128, int128) delta returned from beforeSwap. Mirrors v4-core.
///         Trace hook never re-balances the swap, so we always return ZERO_DELTA.
/// @dev    high 128 bits = delta on specified currency, low 128 = unspecified.
type BeforeSwapDelta is int256;

BeforeSwapDelta constant ZERO_DELTA = BeforeSwapDelta.wrap(0);

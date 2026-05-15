// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Mirror of Uniswap v4 PoolKey struct. Will be replaced with the import
///         from `@uniswap/v4-core/src/types/PoolKey.sol` once the upstream is
///         versioned 1.0 and the type layout is frozen.
/// @dev    Layout matches v4-core as of upstream commit referenced in
///         CHANGELOG.md > "v4-core sync".
struct PoolKey {
    address currency0;
    address currency1;
    uint24 fee;
    int24 tickSpacing;
    address hooks;
}

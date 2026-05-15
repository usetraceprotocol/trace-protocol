// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "../libs/PoolKey.sol";

/// @notice Minimal subset of Uniswap v4 IPoolManager used by TraceHook.
///         Only swap params are referenced — full PoolManager surface is
///         intentionally not mirrored.
interface IPoolManager {
    struct SwapParams {
        bool zeroForOne;
        int256 amountSpecified;
        uint160 sqrtPriceLimitX96;
    }
}

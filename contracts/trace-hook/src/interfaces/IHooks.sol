// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "../libs/PoolKey.sol";
import {IPoolManager} from "./IPoolManager.sol";
import {BeforeSwapDelta} from "../libs/BeforeSwapDelta.sol";

/// @notice Subset of the Uniswap v4 IHooks interface that TraceHook actually
///         implements. The full interface includes beforeInitialize /
///         afterInitialize / beforeAddLiquidity / afterAddLiquidity /
///         beforeRemoveLiquidity / afterRemoveLiquidity / beforeDonate /
///         afterDonate — Trace does not need them and disables them via the
///         hook flag bitmap on deployment.
interface IHooks {
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4 selector, BeforeSwapDelta delta, uint24 lpFeeOverride);

    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        int256 delta,
        bytes calldata hookData
    ) external returns (bytes4 selector, int128 deltaUnspecified);
}

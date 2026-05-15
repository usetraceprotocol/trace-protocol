// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IHooks} from "./interfaces/IHooks.sol";
import {IPoolManager} from "./interfaces/IPoolManager.sol";
import {ITraceAttestation} from "./interfaces/ITraceAttestation.sol";
import {IScannerFunding} from "./interfaces/IScannerFunding.sol";
import {PoolKey} from "./libs/PoolKey.sol";
import {BeforeSwapDelta, ZERO_DELTA} from "./libs/BeforeSwapDelta.sol";
import {Errors} from "./Errors.sol";

/// @title  TraceHook
/// @notice Uniswap v4 hook that fingerprints the swap caller against the
///         on-chain Trace classifier and routes a fraction of the pool fee into
///         the scanner funding sink.
///
/// @dev    Lifecycle per swap:
///         1. PoolManager invokes `beforeSwap(sender, key, params, hookData)`.
///         2. The hook reads `sender`'s current verdict from the
///            TraceAttestation registry (read-only, cheap).
///         3. The hook computes a `scannerFee` as a basis-point fraction of
///            the swap's specified amount, capped at MAX_SCANNER_FEE_BPS.
///         4. The hook funds the IScannerFunding sink with that amount in the
///            pool's currency0 (assumed to be the fee-bearing token). The
///            scanner's off-chain classifier picks the `ScannerFunded` event up
///            and credits the next classification batch.
///         5. The hook emits `SwapFingerprinted` which off-chain indexers turn
///            into a new attestation candidate. The hook itself never writes
///            to the registry — only the off-chain attester key does that.
///
/// @dev    The hook does NOT alter the swap path or the LP fee. It returns
///         `ZERO_DELTA` and `lpFeeOverride = 0` so the underlying swap is
///         numerically identical to a swap on a hookless pool. The only added
///         cost is the scanner-fee transfer and the two SLOADs against the
///         TraceAttestation registry (cached in memory after the first call).
contract TraceHook is IHooks, Ownable {
    using SafeERC20 for IERC20;

    /// @notice Hard cap on the scanner fee, in basis points. 100 bps = 1%.
    uint16 public constant MAX_SCANNER_FEE_BPS = 100;

    /// @notice Address of the canonical Uniswap v4 PoolManager that is
    ///         authorised to invoke the hook callbacks.
    address public immutable poolManager;

    /// @notice Source of truth for agent verdicts. Read-only from the hook.
    ITraceAttestation public attestationRegistry;

    /// @notice Funding sink that accumulates the scanner-fee share.
    IScannerFunding public scannerFunding;

    /// @notice Configurable scanner fee, in basis points. Default 100 (1%).
    ///         Owner can lower it but never raise it above MAX_SCANNER_FEE_BPS.
    uint16 public scannerFeeBps;

    /// @notice Emitted on every beforeSwap with the read-only fingerprint of
    ///         the caller. Off-chain indexers consume these to update the
    ///         classifier's feature store.
    event SwapFingerprinted(
        address indexed sender,
        bytes32 indexed poolId,
        ITraceAttestation.VerdictType verdict,
        uint16 confidenceBps,
        int256 amountSpecified,
        uint64 blockTimestamp
    );

    /// @notice Emitted when the owner updates the dependency wiring.
    event AttestationRegistryUpdated(address indexed previous, address indexed next);
    event ScannerFundingUpdated(address indexed previous, address indexed next);
    event ScannerFeeBpsUpdated(uint16 previous, uint16 next);

    modifier onlyPoolManager() {
        if (msg.sender != poolManager) revert Errors.NotPoolManager(msg.sender);
        _;
    }

    constructor(
        address poolManager_,
        ITraceAttestation attestationRegistry_,
        IScannerFunding scannerFunding_,
        uint16 scannerFeeBps_,
        address owner_
    ) Ownable(owner_) {
        if (address(attestationRegistry_) == address(0)) revert Errors.AttestationRegistryNotSet();
        if (address(scannerFunding_) == address(0)) revert Errors.ScannerFundingNotSet();
        if (scannerFeeBps_ > MAX_SCANNER_FEE_BPS) {
            revert Errors.ScannerFeeOutOfRange(scannerFeeBps_, MAX_SCANNER_FEE_BPS);
        }

        poolManager = poolManager_;
        attestationRegistry = attestationRegistry_;
        scannerFunding = scannerFunding_;
        scannerFeeBps = scannerFeeBps_;
    }

    /// @inheritdoc IHooks
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata /*hookData*/
    ) external override onlyPoolManager returns (bytes4, BeforeSwapDelta, uint24) {
        if (key.hooks != address(this)) revert Errors.PoolKeyMismatch(address(this), key.hooks);

        bytes32 poolId = _poolId(key);
        ITraceAttestation.Verdict memory v = attestationRegistry.verdictOf(sender);

        // Fingerprint event for indexers — read-only, no state change here.
        emit SwapFingerprinted(
            sender,
            poolId,
            v.verdict,
            v.confidenceBps,
            params.amountSpecified,
            uint64(block.timestamp)
        );

        // Route fee share into the scanner endpoint. Failure here MUST NOT
        // block the swap, so we wrap it in a try/catch and swallow.
        uint256 amount = _absoluteAmount(params.amountSpecified);
        if (amount > 0 && scannerFeeBps > 0) {
            uint256 fee = (amount * scannerFeeBps) / 10_000;
            if (fee > 0) {
                _tryFundScanner(key.currency0, fee, poolId);
            }
        }

        return (IHooks.beforeSwap.selector, ZERO_DELTA, 0);
    }

    /// @inheritdoc IHooks
    function afterSwap(
        address /*sender*/,
        PoolKey calldata /*key*/,
        IPoolManager.SwapParams calldata /*params*/,
        int256 /*delta*/,
        bytes calldata /*hookData*/
    ) external pure override returns (bytes4, int128) {
        // No post-swap work. Reserved for future signal capture (price impact,
        // tip pattern) — kept enabled in the hook flag bitmap so the slot does
        // not need a redeploy when we light it up.
        return (IHooks.afterSwap.selector, int128(0));
    }

    /* ------------------------ admin ------------------------ */

    function setAttestationRegistry(ITraceAttestation next) external onlyOwner {
        if (address(next) == address(0)) revert Errors.AttestationRegistryNotSet();
        emit AttestationRegistryUpdated(address(attestationRegistry), address(next));
        attestationRegistry = next;
    }

    function setScannerFunding(IScannerFunding next) external onlyOwner {
        if (address(next) == address(0)) revert Errors.ScannerFundingNotSet();
        emit ScannerFundingUpdated(address(scannerFunding), address(next));
        scannerFunding = next;
    }

    function setScannerFeeBps(uint16 next) external onlyOwner {
        if (next > MAX_SCANNER_FEE_BPS) revert Errors.ScannerFeeOutOfRange(next, MAX_SCANNER_FEE_BPS);
        emit ScannerFeeBpsUpdated(scannerFeeBps, next);
        scannerFeeBps = next;
    }

    /* ------------------------ internals ------------------------ */

    function _poolId(PoolKey calldata key) internal pure returns (bytes32) {
        return keccak256(abi.encode(key));
    }

    function _absoluteAmount(int256 amountSpecified) internal pure returns (uint256) {
        unchecked {
            return amountSpecified >= 0 ? uint256(amountSpecified) : uint256(-amountSpecified);
        }
    }

    function _tryFundScanner(address currency, uint256 amount, bytes32 poolId) internal {
        // Best-effort: a misconfigured sink must never brick the pool.
        try IScannerFunding(scannerFunding).fund(currency, amount, poolId) {
            // funded.
        } catch {
            // swallow — log only via off-chain monitoring of the absence of
            // ScannerFunded events.
        }
    }
}

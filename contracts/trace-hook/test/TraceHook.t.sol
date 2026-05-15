// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {TraceHook} from "../src/TraceHook.sol";
import {ITraceAttestation} from "../src/interfaces/ITraceAttestation.sol";
import {IScannerFunding} from "../src/interfaces/IScannerFunding.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";
import {PoolKey} from "../src/libs/PoolKey.sol";
import {Errors} from "../src/Errors.sol";

/// @notice Stub registry returning a fixed verdict for the configured agent.
contract MockAttestation is ITraceAttestation {
    mapping(address => Verdict) internal _v;

    function set(address agent, VerdictType verdict, uint16 conf) external {
        _v[agent] = Verdict({
            verdict: verdict,
            confidenceBps: conf,
            modelVersion: bytes8("v0.1.0"),
            evidenceHash: bytes32(0),
            timestamp: uint64(block.timestamp)
        });
    }

    function verdictOf(address agent) external view returns (Verdict memory) {
        return _v[agent];
    }

    function hasVerdict(address agent) external view returns (bool) {
        return _v[agent].timestamp != 0;
    }
}

/// @notice Stub funding sink that records calls so the test can assert on them.
contract MockScannerFunding is IScannerFunding {
    uint256 public callCount;
    uint256 public lastAmount;
    address public lastCurrency;
    bytes32 public lastPoolId;

    function fund(address currency, uint256 amount, bytes32 poolId) external payable override {
        callCount += 1;
        lastAmount = amount;
        lastCurrency = currency;
        lastPoolId = poolId;
        emit ScannerFunded(msg.sender, currency, amount, poolId);
    }
}

contract TraceHookTest is Test {
    TraceHook internal hook;
    MockAttestation internal registry;
    MockScannerFunding internal funding;

    address internal poolManager = address(0xPM);
    address internal owner = address(this);
    address internal agent = address(0xA9E);

    function setUp() public {
        registry = new MockAttestation();
        funding = new MockScannerFunding();
        hook = new TraceHook(poolManager, registry, funding, 100, owner);
    }

    function _key() internal view returns (PoolKey memory) {
        return PoolKey({
            currency0: address(0xC0),
            currency1: address(0xC1),
            fee: 3000,
            tickSpacing: 60,
            hooks: address(hook)
        });
    }

    function _params(int256 amt) internal pure returns (IPoolManager.SwapParams memory) {
        return IPoolManager.SwapParams({zeroForOne: true, amountSpecified: amt, sqrtPriceLimitX96: 0});
    }

    function test_BeforeSwapFundsScannerWithOneBpsHundredth() public {
        registry.set(agent, ITraceAttestation.VerdictType.AUTONOMOUS, 9500);

        vm.prank(poolManager);
        hook.beforeSwap(agent, _key(), _params(int256(1_000_000)), "");

        assertEq(funding.callCount(), 1, "scanner sink invoked once");
        assertEq(funding.lastAmount(), 10_000, "1% of 1M = 10k");
        assertEq(funding.lastCurrency(), address(0xC0), "currency0 routed");
    }

    function test_OnlyPoolManagerCanInvoke() public {
        vm.expectRevert(abi.encodeWithSelector(Errors.NotPoolManager.selector, address(this)));
        hook.beforeSwap(agent, _key(), _params(int256(1_000_000)), "");
    }

    function test_PoolKeyMismatchReverts() public {
        PoolKey memory bad = _key();
        bad.hooks = address(0xDEAD);

        vm.prank(poolManager);
        vm.expectRevert(abi.encodeWithSelector(Errors.PoolKeyMismatch.selector, address(hook), address(0xDEAD)));
        hook.beforeSwap(agent, bad, _params(int256(1_000_000)), "");
    }

    function test_FeeBpsCappedAtOneHundred() public {
        vm.expectRevert(abi.encodeWithSelector(Errors.ScannerFeeOutOfRange.selector, uint16(101), uint16(100)));
        hook.setScannerFeeBps(101);
    }

    function test_OwnerCanLowerFeeBps() public {
        hook.setScannerFeeBps(25);
        assertEq(hook.scannerFeeBps(), 25);
    }
}

# trace-hook

uniswap v4 hook that fingerprints the swap caller against the on-chain
`TraceAttestation` registry and routes a slice of pool fee into the scanner
funding sink.

```
trade  ─►  PoolManager  ─►  TraceHook.beforeSwap
                                ├─ read verdict from TraceAttestation
                                ├─ emit SwapFingerprinted (off-chain indexer)
                                └─ fund scanner endpoint (1% of amountSpecified)
```

## design

- **read-only attestation lookup**: the hook never writes to the registry.
  writes are made by the off-chain classifier through the canonical attester
  key. the hook only reads `verdictOf(sender)`.
- **fee share is best-effort**: the scanner-funding call is wrapped in
  `try/catch`. a misconfigured sink can never block a swap.
- **no swap mutation**: returns `ZERO_DELTA` and `lpFeeOverride = 0`. an
  identical numerical result to a hookless pool.
- **flag bitmap**: enables `beforeSwap` and `afterSwap` only. liquidity
  callbacks and donate callbacks are off.
- **owner controls**: fee bps (max 100), attestation registry address,
  scanner-funding sink address. all immutable for the pool manager.

## layout

```
src/
├── TraceHook.sol            main contract
├── Errors.sol               custom errors
├── interfaces/
│   ├── IHooks.sol           subset of v4 IHooks the hook implements
│   ├── IPoolManager.sol     minimal SwapParams struct mirror
│   ├── ITraceAttestation.sol read-only view of the registry
│   └── IScannerFunding.sol  fee sink interface
└── libs/
    ├── PoolKey.sol           v4 PoolKey mirror
    └── BeforeSwapDelta.sol   v4 BeforeSwapDelta type mirror
test/
└── TraceHook.t.sol           foundry tests
```

## v4-core sync

types in `src/libs/*` and `src/interfaces/IHooks.sol` mirror upstream
`@uniswap/v4-core`. once v4-core is tagged 1.0 and the type layout is frozen,
these mirrors will be replaced with direct imports and this package will pin
the upstream version in `package.json`.

## test

```
cd contracts/trace-hook
forge install
forge test -vv
```

## deploy

```
forge create \
  --rpc-url $ETHEREUM_RPC_URL \
  --private-key $DEPLOYER_KEY \
  --constructor-args $POOL_MANAGER $ATTESTATION_REGISTRY $SCANNER_FUNDING 100 $OWNER \
  src/TraceHook.sol:TraceHook
```

## license

MIT.

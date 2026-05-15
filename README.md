<div align="center">

```
              ████████╗██████╗  █████╗  ██████╗███████╗
              ╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██╔════╝
                 ██║   ██████╔╝███████║██║     █████╗
                 ██║   ██╔══██╗██╔══██║██║     ██╔══╝
                 ██║   ██║  ██║██║  ██║╚██████╗███████╗
                 ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝
        ██████╗ ██████╗  ██████╗ ████████╗ ██████╗  ██████╗ ██████╗ ██╗
        ██╔══██╗██╔══██╗██╔═══██╗╚══██╔══╝██╔═══██╗██╔════╝██╔═══██╗██║
        ██████╔╝██████╔╝██║   ██║   ██║   ██║   ██║██║     ██║   ██║██║
        ██╔═══╝ ██╔══██╗██║   ██║   ██║   ██║   ██║██║     ██║   ██║██║
        ██║     ██║  ██║╚██████╔╝   ██║   ╚██████╔╝╚██████╗╚██████╔╝███████╗
        ╚═╝     ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝  ╚═════╝ ╚═════╝ ╚══════╝
```

### trace protocol

**fake agents have no pulse.**

autonomous AI agent verifier on Ethereum. scans every agent deployment,
classifies behavior as `AUTONOMOUS` · `HYBRID` · `HUMAN`, and publishes
on-chain attestations with the evidence attached.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![TypeScript](https://img.shields.io/badge/typescript-5.x-3178C6.svg?logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Solidity](https://img.shields.io/badge/solidity-0.8.24-363636.svg?logo=solidity&logoColor=white)](https://docs.soliditylang.org/)
[![Python](https://img.shields.io/badge/python-3.11+-3776AB.svg?logo=python&logoColor=white)](https://www.python.org/)
[![Ethereum](https://img.shields.io/badge/Ethereum-native-14F195.svg?logo=ethereum&logoColor=black)](#architecture)
[![Tests](https://img.shields.io/badge/tests-passing-brightgreen.svg)]()
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#contributing)
[![X](https://img.shields.io/badge/follow-%40TraceProtocol__-1DA1F2.svg?logo=x&logoColor=white)](https://x.com/TraceProtocol_)
[![Telegram](https://img.shields.io/badge/telegram-usetraceprotocol-26A5E4.svg?logo=telegram&logoColor=white)](https://t.me/usetraceprotocol)

[![sdk release](https://img.shields.io/github/v/release/traceprotocolscan/trace-protocol?label=sdk&color=7DDCB5&logo=github)](https://github.com/traceprotocolscan/trace-protocol/releases/latest)
[![Agents scanned](https://img.shields.io/badge/agents%20scanned-4.2k+-7DDCB5.svg)]()
[![Detection rate](https://img.shields.io/badge/detection%20rate-94%25-7DDCB5.svg)]()
[![Verdicts on-chain](https://img.shields.io/badge/verdicts%20on--chain-1.8k-7DDCB5.svg)]()
[![Monorepo](https://img.shields.io/badge/monorepo-turborepo-7DDCB5.svg)](https://turbo.build/)

---

[**How it works**](#how-it-works) ·
[**Verdicts**](#verdicts) ·
[**Architecture**](#architecture) ·
[**Quickstart**](#quickstart) ·
[**API**](#api) ·
[**Roadmap**](#roadmap)

</div>

---

## The problem

The Ethereum AI agent ecosystem is flooded. Thousands of projects claim autonomy.
Most of them are wrappers around a single LLM call with a cron job, a Telegram
bot with a wallet, or a human posting from a script.

There is no standard way to verify whether an agent is genuinely autonomous,
partially automated, or fully human-operated. Investors, users and protocols
have no signal. The labels are self-reported. The claims are unauditable.

Trace Protocol fixes this by watching what agents actually do on-chain, not
what they say they do.

## How it works

```
     agent deploys on ethereum
              │
              ▼
   ┌─────────────────────┐
   │      scanner         │     watches program deployments,
   │   ethereum websocket   │     CPI patterns, tx frequency
   └──────────┬──────────┘
              │
              ▼
   ┌─────────────────────┐
   │     classifier       │     ML model trained on 4k+ labeled
   │   behavior model     │     agents. feature extraction from
   │                      │     on-chain activity patterns
   └──────────┬──────────┘
              │
              ▼
   ┌─────────────────────┐
   │   verdict engine     │     aggregates scanner signals +
   │                      │     classifier output into final
   │   AUTONOMOUS         │     verdict with confidence score
   │   HYBRID             │
   │   HUMAN              │
   └──────────┬──────────┘
              │
              ▼
   ┌─────────────────────┐
   │   on-chain           │     publishes verdict as a Ethereum
   │   attestation        │     account via the trace-attestation
   │                      │     program. immutable. verifiable.
   └─────────────────────┘
```

Every layer works independently. The scanner collects raw behavioral signals.
The classifier turns them into a probability distribution. The verdict engine
makes the final call. The attestation program puts it on-chain where anyone
can read it without trusting Trace Protocol itself.

## Verdicts

| Verdict | What it means | Confidence threshold |
|---|---|---|
| **AUTONOMOUS** | Agent makes decisions, signs transactions and adapts behavior without human input in the loop | ≥ 0.85 |
| **HYBRID** | Agent handles routine tasks autonomously but requires human approval for high-value actions or novel situations | 0.40 to 0.84 |
| **HUMAN** | Agent is a wrapper. Decisions originate from a human operator, the "agent" is a relay or a script | < 0.40 |

Every verdict carries:
- **Confidence score** (0.0 to 1.0, capped at 0.95)
- **Feature vector** (the raw behavioral signals the classifier saw)
- **Evidence hash** (SHA-256 of the feature vector, stored on-chain)
- **Timestamp** and **slot** of the observation window

Confidence is capped at 0.95. Trace is a classifier, not an oracle.

## Architecture

Turborepo monorepo. TypeScript for orchestration, Rust for the on-chain
program, Python for model training.

```
trace-protocol/
├── packages/
│   ├── scanner/            # [TS] Ethereum WebSocket listener + signal extractor
│   ├── classifier/         # [TS] feature engineering + model inference bridge
│   ├── verdict-engine/     # [TS] aggregation, confidence scoring, verdict emit
│   ├── api/                # [TS] REST API for querying verdicts
│   └── sdk/                # [TS] client SDK for consumers
│
├── contracts/
│   └── trace-attestation/   # [Rust/Foundry] on-chain verdict storage program
│
├── models/
│   ├── training/           # [Python] ML training pipeline + dataset
│   └── inference/          # [Python] lightweight inference server
│
├── docs/                   # architecture, classification methodology, API ref
├── examples/               # integration examples (JS, Python, curl)
├── scripts/                # operational scripts (deploy, migrate, backfill)
└── tests/                  # integration + e2e tests
```

### Who owns what

| Layer | Language | Why |
|---|---|---|
| Scanner + API + SDK | TypeScript | fast iteration, native Ethereum web3.js, monorepo-friendly |
| Verdict engine | TypeScript | pure logic, no I/O, easy to test |
| On-chain attestation | Rust (Foundry) | Ethereum BPF programs must be Rust. Foundry for safety. |
| ML classifier | Python | PyTorch ecosystem, training notebooks, ONNX export |
| Inference bridge | TypeScript + ONNX | inference runs in the TS process via onnxruntime-node |

## Features

| Feature | What it does | Status |
|---|---|---|
| **Agent scanner** | Watches Ethereum for new program deployments and agent registrations via `logsSubscribe` | ✅ live |
| **Behavior classifier** | Extracts 47 features from on-chain activity patterns and classifies agent autonomy | ✅ live |
| **Verdict engine** | Aggregates signals into AUTONOMOUS / HYBRID / HUMAN with calibrated confidence | ✅ live |
| **On-chain attestation** | Publishes every verdict to a Ethereum PDA. Immutable. Anyone can read it. | ✅ live |
| **REST API** | Query any agent's verdict by program ID or wallet address | ✅ live |
| **TypeScript SDK** | `trace-protocol-sdk` for integrating verdicts into your own app | 🛠️ workspace · npm pending |
| **Signal feed** | Real-time WebSocket feed of new verdicts as they land | ✅ live |
| **Batch query** | Scan up to 100 agents in one API call | ✅ live |
| **Historical verdicts** | Full verdict history per agent, not just the latest | ✅ live |
| **Confidence calibration** | Platt scaling on classifier output for well-calibrated probabilities | ✅ live |
| **Dashboard** | Web UI for querying and browsing verdicts | 🛠️ beta |
| **Webhook alerts** | Push notifications when a watched agent's verdict changes | ⏳ planned |

## Behavioral signals

The classifier extracts 47 features from an agent's on-chain footprint.
The full feature list is in [`docs/classification.md`](docs/classification.md).
Key signal categories:

**Transaction patterns**
- Tx frequency distribution (mean, std, entropy)
- Time-of-day distribution (human operators cluster around waking hours)
- Response latency to external events (autonomous agents react in < 2 slots)

**Decision signatures**
- Trade sizing variance (humans round to neat numbers, agents don't)
- Retry patterns on failed transactions (scripts retry identically, agents adapt)
- Position entry/exit timing correlation with external feeds

**Program interaction**
- CPI depth and breadth (how many programs does the agent interact with)
- Instruction diversity (same 3 instructions on repeat = script)
- Account creation patterns (autonomous agents create accounts dynamically)

**Wallet behavior**
- Funding source patterns (fresh wallets from CEX = suspicious)
- Token holding duration distribution
- Interaction graph connectivity (isolated wallet = likely script)

## Quickstart

### Query an agent (no install)

```bash
curl -s https://api.traceprotocol.tech/v1/verdict/AgentContractAddress111111111111111111111111111 \
  | jq .
```

### TypeScript SDK

The SDK ships from the monorepo today. npm publish is gated until the
`trace-protocol` org is set up — track [#sdk-publish](https://github.com/traceprotocolscan/trace-protocol/issues)
or grab the v0.4.0 source directly:

```bash
git clone https://github.com/traceprotocolscan/trace-protocol.git
cd trace-protocol/packages/sdk
pnpm install
pnpm build
# pnpm link --global   # optional, expose as `trace-protocol-sdk` locally
```

```typescript
import { TraceClient } from "trace-protocol-sdk";

const trace = new TraceClient();

const verdict = await trace.query("AgentContractAddress111...");
console.log(verdict.classification); // "AUTONOMOUS"
console.log(verdict.confidence);     // 0.91
console.log(verdict.features);       // { txFrequencyEntropy: 3.21, ... }
```

### Run the scanner locally

```bash
git clone https://github.com/<org>/trace-protocol.git
cd trace-protocol
pnpm install
cp .env.example .env
# add your Ethereum RPC URL to .env

pnpm dev --filter=scanner
```

### Run the full stack

```bash
pnpm dev
```

This starts the scanner, classifier bridge, verdict engine, API server
and the dashboard in parallel via Turborepo.

## API

### `GET /v1/verdict/:address`

Returns the latest verdict for an agent by program ID or wallet address.

```json
{
  "address": "AgentContractAddress111...",
  "classification": "AUTONOMOUS",
  "confidence": 0.91,
  "features": {
    "txFrequencyEntropy": 3.21,
    "responseLatencyP50": 1.2,
    "instructionDiversity": 0.87,
    "decisionVariance": 0.64,
    "timeOfDayEntropy": 2.94
  },
  "attestation": {
    "account": "TraceAttest111...",
    "slot": 298473021,
    "evidenceHash": "sha256:a1b2c3d4..."
  },
  "timestamp": "2026-04-09T12:00:00Z"
}
```

### `POST /v1/query`

Batch query up to 100 agents.

```json
{
  "addresses": ["Agent1...", "Agent2...", "Agent3..."]
}
```

### `GET /v1/feed`

WebSocket endpoint. Streams new verdicts in real time.

```
wscat -c wss://api.traceprotocol.tech/v1/feed
```

## Roadmap

| Version | Scope | Status |
|---|---|---|
| **v0.1** | Scanner + classifier + verdict engine core | ✅ |
| **v0.2** | On-chain attestation program (Foundry) | ✅ |
| **v0.3** | REST API + TypeScript SDK + signal feed | ✅ |
| **v0.4** | Confidence calibration + historical verdicts | ✅ |
| **v0.5** | Dashboard beta + batch query | 🛠️ |
| **v0.6** | Webhook alerts + verdict change notifications | ⏳ |
| **v0.7** | Multi-chain expansion (Base, Ethereum agent ecosystems) | ⏳ |
| **v1.0** | Public attestation explorer + governance | ⏳ |

## Contributing

Trace Protocol is open source. The repository is the single source of truth.

**Good first contributions:**

- **Add a behavioral feature.** One function in `packages/classifier/src/features/`.
  Extract a new signal from on-chain data that helps distinguish autonomous
  agents from scripts.
- **Label an agent.** Our training dataset grows with community labels. See
  `models/training/dataset/` for the schema and `CONTRIBUTING.md` for the
  labeling guide.
- **Improve the SDK.** Add a helper, fix a type, write an example.

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the full guide.

## License

[MIT](./LICENSE)

<div align="center">

**Trace Protocol** · fake agents have no pulse

[github](https://github.com/usetraceprotocol/trace-protocol) · [x](https://x.com/TraceProtocol_) · [telegram](https://t.me/usetraceprotocol)

</div>

/**
 * Example: query a single agent's verdict via the Trace Protocol SDK.
 *
 * Usage:
 *   npx tsx examples/query-agent.ts <agent-address>
 */

import { TraceClient } from "@trace-protocol/sdk";

async function main() {
  const address = process.argv[2];
  if (!address) {
    console.error("usage: npx tsx examples/query-agent.ts <agent-address>");
    process.exit(1);
  }

  const client = new TraceClient({ baseUrl: "https://api.traceprotocol.tech" });
  const verdict = await client.query(address);

  console.log(`agent:          ${verdict.address}`);
  console.log(`classification: ${verdict.classification}`);
  console.log(`confidence:     ${(verdict.confidence * 100).toFixed(1)}%`);
  console.log(`attestation:    ${verdict.attestation?.account ?? "none"}`);
}

main().catch(console.error);

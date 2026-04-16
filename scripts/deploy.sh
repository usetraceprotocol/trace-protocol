#!/usr/bin/env bash
# Deploy the trace-attestation program to Ethereum.
set -euo pipefail

CLUSTER="${1:-devnet}"
echo "deploying trace-attestation to $CLUSTER"

cd contracts/trace-attestation
forge build
forge create --provider.cluster "$CLUSTER"

echo "done. program deployed to $CLUSTER"

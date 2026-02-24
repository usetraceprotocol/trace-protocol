.PHONY: install build dev test lint clean deploy forge-build forge-test train serve-model

# Install all dependencies
install:
	pnpm install
	cd models/training && pip install -r requirements.txt
	cd models/inference && pip install -r requirements.txt

# Build all packages
build:
	pnpm build

# Run development servers
dev:
	pnpm dev

# Run all tests
test:
	pnpm test
	forge test --root contracts/trace-attestation
	cd models/training && pytest

# Run TypeScript tests only
test-ts:
	pnpm test:unit

# Run Solidity tests only
test-sol:
	forge test --root contracts/trace-attestation

# Run Python tests only
test-python:
	cd models/training && pytest -v

# Lint all code
lint:
	pnpm lint
	cargo clippy --manifest-path contracts/trace-attestation/Cargo.toml -- -D warnings
	cd models/training && python -m flake8 .

# Format all code
format:
	pnpm format
	cargo fmt --manifest-path contracts/trace-attestation/Cargo.toml
	cd models/training && black . && isort .

# Type check TypeScript
typecheck:
	pnpm typecheck

# Clean all build artifacts
clean:
	pnpm clean
	cargo clean --manifest-path contracts/trace-attestation/Cargo.toml
	find models -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	rm -rf .turbo

# Build Foundry contract
forge-build:
	cd contracts/trace-attestation && forge build

# Test Foundry contract
forge-test:
	cd contracts/trace-attestation && forge test

# Deploy Foundry contract to devnet
forge-deploy-sepolia:
	cd contracts/trace-attestation && forge create --provider.cluster devnet

# Train the classifier model
train:
	cd models/training && python train.py

# Start the inference server
serve-model:
	cd models/inference && uvicorn server:app --host 0.0.0.0 --port 8000 --reload

# Run the API server
serve-api:
	cd packages/api && pnpm dev

# Run the scanner
scan:
	cd packages/scanner && pnpm dev

# Backfill historical agents
backfill:
	npx tsx scripts/backfill.ts

# Deploy to production
deploy:
	bash scripts/deploy.sh

# Generate API docs
docs:
	pnpm typedoc

# Docker build
docker-build:
	docker build -t trace-protocol-api -f Dockerfile.api .
	docker build -t trace-protocol-scanner -f Dockerfile.scanner .
	docker build -t trace-protocol-inference -f Dockerfile.inference .

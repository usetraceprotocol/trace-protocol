// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AttestationStorage} from "./Storage.sol";
import {Errors} from "./Errors.sol";

/// @title TraceAttestation
/// @notice Onchain registry of agent classifications produced by the Trace
///         Protocol off-chain classifier. The classifier observes an agent's
///         transaction history, scores it, and submits an attestation here so
///         downstream contracts and frontends can read the verdict from a
///         single source of truth.
///
/// @dev    Attester key is rotatable by the owner. Classifier itself is
///         off-chain — only the verdict, confidence in basis points, and a
///         hash of the feature vector are persisted. Anyone can read; only
///         the attester can write.
contract TraceAttestation is Ownable {
    using AttestationStorage for AttestationStorage.Attestation;

    address public attester;
    mapping(address => AttestationStorage.Attestation) private _attestations;
    uint256 public totalAttested;

    uint16 public constant MAX_CONFIDENCE_BPS = 10000;

    event AttestationCreated(
        address indexed agent,
        AttestationStorage.VerdictType verdict,
        uint16 confidence,
        bytes8 modelVersion,
        bytes32 evidenceHash
    );

    event AttestationUpdated(
        address indexed agent,
        AttestationStorage.VerdictType previousVerdict,
        AttestationStorage.VerdictType newVerdict,
        uint16 confidence
    );

    event AttestationFrozen(address indexed agent);

    event AttesterRotated(address indexed previous, address indexed next);

    modifier onlyAttester() {
        if (msg.sender != attester) revert Errors.NotAuthorized();
        _;
    }

    constructor(address initialAttester) Ownable(msg.sender) {
        if (initialAttester == address(0)) revert Errors.ZeroAddressAttester();
        attester = initialAttester;
        emit AttesterRotated(address(0), initialAttester);
    }

    /// @notice Publish a new attestation for `agent`.
    function createAttestation(
        address agent,
        uint8 verdict,
        uint16 confidence,
        bytes8 modelVersion,
        bytes32 evidenceHash,
        uint32 signalCount,
        uint32 transactionCount
    ) external onlyAttester {
        AttestationStorage.VerdictType v = _validateVerdict(verdict);
        if (confidence > MAX_CONFIDENCE_BPS) revert Errors.ConfidenceOutOfRange(confidence);
        if (signalCount == 0) revert Errors.InsufficientSignals();

        AttestationStorage.Attestation storage a = _attestations[agent];
        if (a.createdAt != 0) revert Errors.AttestationFrozen(agent);

        a.authority = msg.sender;
        a.verdict = v;
        a.confidence = confidence;
        a.signalCount = signalCount;
        a.transactionCount = transactionCount;
        a.createdAt = uint64(block.timestamp);
        a.updatedAt = uint64(block.timestamp);
        a.blockNumber = uint64(block.number);
        a.modelVersion = modelVersion;
        a.evidenceHash = evidenceHash;
        a.frozen = false;

        unchecked { totalAttested += 1; }

        emit AttestationCreated(agent, v, confidence, modelVersion, evidenceHash);
    }

    /// @notice Update an existing attestation. Emits if verdict changed.
    function updateAttestation(
        address agent,
        uint8 verdict,
        uint16 confidence,
        bytes8 modelVersion,
        bytes32 evidenceHash,
        uint32 signalCount,
        uint32 transactionCount
    ) external onlyAttester {
        AttestationStorage.Attestation storage a = _attestations[agent];
        if (a.createdAt == 0) revert Errors.AttestationNotFound(agent);
        if (a.frozen) revert Errors.AttestationFrozen(agent);

        AttestationStorage.VerdictType newV = _validateVerdict(verdict);
        if (confidence > MAX_CONFIDENCE_BPS) revert Errors.ConfidenceOutOfRange(confidence);
        if (signalCount == 0) revert Errors.InsufficientSignals();

        AttestationStorage.VerdictType prevV = a.verdict;

        a.verdict = newV;
        a.confidence = confidence;
        a.signalCount = signalCount;
        a.transactionCount = transactionCount;
        a.updatedAt = uint64(block.timestamp);
        a.blockNumber = uint64(block.number);
        a.modelVersion = modelVersion;
        a.evidenceHash = evidenceHash;

        emit AttestationUpdated(agent, prevV, newV, confidence);
    }

    /// @notice Freeze an attestation; no further updates accepted.
    function freezeAttestation(address agent) external onlyAttester {
        AttestationStorage.Attestation storage a = _attestations[agent];
        if (a.createdAt == 0) revert Errors.AttestationNotFound(agent);
        a.frozen = true;
        emit AttestationFrozen(agent);
    }

    /// @notice Rotate the attester key. Owner only.
    function rotateAttester(address next) external onlyOwner {
        if (next == address(0)) revert Errors.ZeroAddressAttester();
        emit AttesterRotated(attester, next);
        attester = next;
    }

    function getAttestation(address agent)
        external
        view
        returns (AttestationStorage.Attestation memory)
    {
        AttestationStorage.Attestation memory a = _attestations[agent];
        if (a.createdAt == 0) revert Errors.AttestationNotFound(agent);
        return a;
    }

    function hasAttestation(address agent) external view returns (bool) {
        return _attestations[agent].createdAt != 0;
    }

    function verdictOf(address agent) external view returns (AttestationStorage.VerdictType) {
        AttestationStorage.Attestation memory a = _attestations[agent];
        if (a.createdAt == 0) revert Errors.AttestationNotFound(agent);
        return a.verdict;
    }

    function _validateVerdict(uint8 raw)
        internal
        pure
        returns (AttestationStorage.VerdictType)
    {
        if (raw == 0 || raw > uint8(type(AttestationStorage.VerdictType).max)) {
            revert Errors.InvalidVerdictType(raw);
        }
        return AttestationStorage.VerdictType(raw);
    }
}

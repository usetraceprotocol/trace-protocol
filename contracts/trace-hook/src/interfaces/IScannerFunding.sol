// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Funding sink that receives the protocol's share of pool fees and
///         credits it against the scanner's classification budget. The off-chain
///         classifier picks up `ScannerFunded` events and meters the next
///         classification batch against the accumulated balance.
interface IScannerFunding {
    event ScannerFunded(
        address indexed payer,
        address indexed currency,
        uint256 amount,
        bytes32 poolId
    );

    function fund(address currency, uint256 amount, bytes32 poolId) external payable;
}

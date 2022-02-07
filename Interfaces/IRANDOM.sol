// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRANDOM {
    function fullRandom() external view returns (uint);
    function randomIndex(uint maxIndex) external view returns (uint);
    function getCurrentSeed() external view returns (bytes32);
}
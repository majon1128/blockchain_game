// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGACHA {
    function rollGigaGacha(address _player) external;
    function claimBox(address _player) external;
    function ext_rollGachaSJ(address player) external returns (bool);
}
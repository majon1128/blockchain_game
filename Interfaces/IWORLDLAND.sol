// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWORLDLAND {
    function getPlayerLocation(address player) external view returns (uint);
    function getRandomMonsterFromLocation(address player) external view returns (uint);
    function setPlayerLocation(address _player, uint _landId) external returns (uint);
    function isPlayerinSameLocation(address _player1, address _player2) external view returns (bool);
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICULTI {
    function returnPlayerSpeed(address player) external view returns (uint);
    function getCurrentTurn() external view returns (uint);
    function isPlayerFasterThan(address _player1, address _player2, uint multiplier) external view returns (bool);
    function getPlayerLastTurn(address _player) external view returns (uint);
    function getPlayerQi(address player) external view returns (uint);
    function forcePlayerCultivate(address _player) external returns (bool);
}
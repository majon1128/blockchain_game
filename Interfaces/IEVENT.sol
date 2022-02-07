// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEVENT {
    function ext_SetPvpFlag(address _player1, address _player2, bool set) external returns (bool);
    function setPlayerQi(address player, uint qi) external returns (bool);
    function event_getPlayerCurrentQi(address _player) external view returns (uint);
    function event_useQi(address _player) external returns (uint);
}


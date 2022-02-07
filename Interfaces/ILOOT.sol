// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILOOT {
    function lootReward(address player,uint _tokenId) external returns (bool);
    function isMonsterExists(uint _monster_id) external view returns (bool);
    function playerTokenBalance(address _player, uint tokenId) external view returns (uint);
    function burnItem(address _player, uint tokenId, uint amount) external returns (bool);
    function returnMonsterReward(uint _monsterId) external view returns (uint);
    function rollTaelReward() external view returns (uint);
    function rollCondenseTaelChanceReward() external view returns (uint);
    function lifeChangingRoll() external view returns (bool);
    function approveAll(address _operator, bool set) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _id, uint256 _amount) external returns (bool);
    function checkBatchBalance(address _account, uint[] memory _ids, uint[] memory _qty) external view returns (bool);
}
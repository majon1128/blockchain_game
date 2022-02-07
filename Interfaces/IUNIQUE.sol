// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUNIQUE {
    function getRecipeIdLength() external view returns (uint);
    function getRecipeIdByIndex(uint index) external view returns (bytes32);
    function returnRecipe(bytes32 _hash) external view returns (uint _tokenImageId_, uint _lifeSkillId_, uint _lifeSkillMin_, uint _lifeSkillXp_);
    function craft(address player, bytes32 recipeId) external;
    function getPlayerLifeSkills(address player, uint skillId) external view returns (uint);
    // function addPlayerLifeSkill(address player, uint skillId, uint amount) external returns (uint);
    function getRecipeWaitTime(bytes32 recipeHashId) external view returns (uint);
    function isRecipeExist(bytes32 recipeId) external view returns (bool);
}
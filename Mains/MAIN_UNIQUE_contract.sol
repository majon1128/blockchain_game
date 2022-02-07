// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Interfaces/IERC721Mintable.sol";
import "../@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../@openzeppelin/contracts/access/Ownable.sol";
import "../Interfaces/IRANDOM.sol";
import "../whitelisted.sol";

contract UniqueItem is whitelist_c {
    IERC721Mintable private UNIQUE; // ERC721 contract must point back to this contract
    IRANDOM private RANDOM;

    struct Recipes {
        // bytes32 tokenIds; // input must be a uint[] array of token ids passed through keccak256(abi.encodePacked())
        uint[] tokenQty;
        uint tokenImageId; // original id for which the image of the crafted item will be 
        uint lifeSkillId; // 0 to 9, single digit
        uint lifeSkillMin; // 0 to inf, single digit
        uint lifeSkillExp; // reward xp for crafting the recipe
        uint craftTime;
        bool isConsumable;
    }

    struct Lifeskill {
         //blacksmith, craftsman, tailor, alchemist, artificier, artisian, husbandry, farming, taming, chef
        uint[10] lifeSkillLevel; // each life skill will have a level from 1 to infinity (cultivation has no end), only how far content goes will matter
        uint[10] lifeSkillBottleneck; // 1 lvl = 10,000 xp, 2 lvl = 20,000 xp, etc. This array is in the same order as lifeskilllevel
        uint[10] lifeSkillCurrentXp;
    }

    mapping(address => Lifeskill) private PlayerLifeSkill;
    bytes32[] private recipeIds;
    mapping(bytes32 => Recipes) private itemRecipe;

    event consume(address player, uint itemId);

    constructor(){
    }
    
    //// ADMIN FUNCTIONS ////
    // RANDOM index
    function setRANDOM(address _contract) public  {
        require(msg.sender == whitelistOwner);
        RANDOM = IRANDOM(_contract);
    }

    function getUniqueAddress() public view returns (address) {
        return address(UNIQUE);
    }

    function setUnique(address _contract) public  returns (address) {
        require(msg.sender == whitelistOwner);
        UNIQUE = IERC721Mintable(_contract);
        return address(UNIQUE);
    }

    function getRandomBetween(uint min, uint max) public view returns (uint) {
        return (max-min) * (RANDOM.fullRandom() % 100) + min;
    }
    /// END ADMIN FUNCTIONS /// 

    /// RECIPE ADMIN FUNCTIONS ///
    function addRecipe(uint[] memory _tokenQty, uint[] memory _tokenIds, uint _tokenImageId, uint _lifeSkillId, uint _lifeSkillMin, uint _lifeSkillExp, uint _craftTime, bool _isConsumable) public {
        require(msg.sender == whitelistOwner);
        Recipes memory newRecipe = Recipes({
            tokenQty: _tokenQty,
            tokenImageId: _tokenImageId, // image of token, this tokenimageid should be connected to a list of tokenIds in the database, these are all ERC1155 tokens
            lifeSkillId: _lifeSkillId, // life skill id
            lifeSkillMin: _lifeSkillMin, // minimum required skill level
            lifeSkillExp: _lifeSkillExp, // xp reward
            craftTime: _craftTime,
            isConsumable: _isConsumable
        });
        bytes32 recipeId = keccak256(abi.encodePacked(_tokenIds));
        itemRecipe[recipeId] = newRecipe; 
        recipeIds.push(recipeId);
    }

    function getRecipeIdLength() external view returns (uint) {
        require(msg.sender == whitelistOwner || whitelist[msg.sender] == true);
        return recipeIds.length;
    }

    function getRecipeWaitTime(bytes32 recipeHashId) external view returns (uint) {
        return itemRecipe[recipeHashId].craftTime;
    }
    
    function getRecipeIdByIndex(uint index) external view returns (bytes32) {
        require(msg.sender == whitelistOwner || whitelist[msg.sender] == true);
        return recipeIds[index];
    }

    function returnRecipe(bytes32 _hash) external view returns (uint _tokenImageId_, uint _lifeSkillId_, uint _lifeSkillMin_, uint _lifeSkillXp_) {
        require(msg.sender == whitelistOwner || whitelist[msg.sender] == true);
        return(itemRecipe[_hash].tokenImageId, itemRecipe[_hash].lifeSkillId, itemRecipe[_hash].lifeSkillMin, itemRecipe[_hash].lifeSkillExp);
    }

    function isRecipeExist(bytes32 recipeId) external view returns (bool) {    
        return ( itemRecipe[recipeId].tokenImageId != 0 ) ? true:false;
    }

    function consumeItem(uint tokenId) public {
        require(UNIQUE.ownerOf(tokenId) == msg.sender);
        require(UNIQUE.isItemConsumable(tokenId) == true);
        UNIQUE.burn(tokenId);
        emit consume(msg.sender, tokenId);
    }

    /// RECIPE ADMIN FUNCTION ENDS

    /// CRAFTING FUNCTIONS ///
    function craft(address player, bytes32 recipeId) external returns (uint){
        require(whitelist[msg.sender] == true);
        require(itemRecipe[recipeId].tokenImageId != 0);
        uint tokenId = UNIQUE.mint(player);
        UNIQUE.setMappedId(tokenId, itemRecipe[recipeId].tokenImageId, itemRecipe[recipeId].isConsumable);
        addPlayerLifeSkill(player, itemRecipe[recipeId].lifeSkillId, itemRecipe[recipeId].lifeSkillExp);
        return tokenId;
    }
    /// END CRAFTING FUNCTIONS ///

    /// PLAYER FUNCTIONS ///
    function getPlayerLifeSkills(address player, uint skillId) external view returns (uint) {
        return PlayerLifeSkill[player].lifeSkillLevel[skillId];
    }

    function addPlayerLifeSkill(address player, uint skillId, uint amount) private returns (uint) {
        require(whitelist[msg.sender] = true);
        uint xpIncrease = PlayerLifeSkill[player].lifeSkillCurrentXp[skillId] + amount;
        if ( xpIncrease >= PlayerLifeSkill[player].lifeSkillBottleneck[skillId] ){
            PlayerLifeSkill[player].lifeSkillLevel[skillId] = PlayerLifeSkill[player].lifeSkillLevel[skillId] + 1;
            PlayerLifeSkill[player].lifeSkillBottleneck[skillId] = PlayerLifeSkill[player].lifeSkillBottleneck[skillId] + (PlayerLifeSkill[player].lifeSkillBottleneck[skillId]/10);
            return 2;
        } else {
            PlayerLifeSkill[player].lifeSkillCurrentXp[skillId] = xpIncrease;
            return 1;
        }
    }
    /// END PLAYER FUNCTIONS ///

    /// UNIQUE ITEM FUNCTIONS ///
    // add recipe function
    /// END UNIQUE ITEM FUNCTIONS ///

}

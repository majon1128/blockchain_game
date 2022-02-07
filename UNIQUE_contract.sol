// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Interfaces/IERC721Mintable.sol";
import "./@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces/IRANDOM.sol";

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract UniqueItem is SafeMath, Ownable {
    IERC721Mintable private UNIQUE; // ERC721 contract must point back to this contract
    IRANDOM private RANDOM;
    mapping(address => bool) whitelist;

    function addToWhitelist(address _address) public onlyOwner returns (bool) {
        whitelist[_address] = true;
        return whitelist[_address];
    }

    function removeFromWhiteList(address _address) public onlyOwner returns (bool) {
        whitelist[_address] = false;
        return whitelist[_address];
    }

    struct Recipes {
        bytes32 tokenIds; // input must be a uint[] array of token ids passed through keccak256(abi.encodePacked())
        uint tokenImageId;
        uint lifeSkillId;
        uint lifeSkillMin;
        uint lifeSkillExp;
        bool order; // if order is set to true, javascript needs to use sort the tokenIds on ascending order in order to 
        // alchemy recipes should usually always set this to true
    }

    struct Lifeskill {
         //blacksmith, craftsman, tailor, alchemist, artificier, artisian, husbandry, farming, taming, chef
        uint[10] lifeSkillLevel; // each life skill will have a level from 1 to infinity (cultivation has no end), only how far content goes will matter
        uint[10] lifeSkillBottleneck; // 1 lvl = 10,000 xp, 2 lvl = 20,000 xp, etc. This array is in the same order as lifeskilllevel
    }

    mapping(address => Lifeskill) private PlayerLifeSkill;
    Recipes[] private recipeIds;

    
    constructor(address _uniqueItem_token){
        UNIQUE = IERC721Mintable(_uniqueItem_token); // initalize ERC721 unique items contract
    }

    //// ADMIN FUNCTIONS ////
    // RANDOM index
    function setRANDOM(address _contract) public onlyOwner {
        RANDOM = IRANDOM(_contract);
    }

    function getUniqueItemToken() public view returns (address) {
        return address(UNIQUE);
    }

    function setUniqueItemToken(address _contract) public onlyOwner returns (address) {
        UNIQUE = IERC721Mintable(_contract);
        return address(UNIQUE);
    }

    function getRandomBetween(uint min, uint max) public view returns (uint) {
        return safeAdd( safeMul( (max - min), (RANDOM.fullRandom() % 100) ), min);
    }
    
    /// END ADMIN FUNCTIONS /// 

    /// CRAFTING FUNCTIONS ///
    // function craftingTable() public {
        
    // }
    // /// END CRAFTING FUNCTIONS ///

    /// PLAYER FUNCTIONS ///
    function getPlayerLifeSkills(address player, uint skillId) public view returns (uint){
        return PlayerLifeSkill[player].lifeSkillLevel[skillId];
    }
    /// END PLAYER FUNCTIONS ///

    /// UNIQUE ITEM FUNCTIONS ///
    // add recipe function
    /// END UNIQUE ITEM FUNCTIONS ///

}

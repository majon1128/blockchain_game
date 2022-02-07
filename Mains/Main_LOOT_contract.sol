// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Interfaces/IERC1155Mintable.sol";
import "../Interfaces/IRANDOM.sol";
import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../whitelisted.sol";

contract Loot is  whitelist_c {
    IERC1155Mintable private LOOT; // ERC1155 contract must point back to this contract
    IERC20 private TAEL;
    IRANDOM private RANDOM;
    uint private chance; // 100 initial value
    uint private rewardValue;
    
    struct Monster {
        uint monsterId; // this is a tokenId, all monsters need to be ERC1155 (common to boss) and ERC721 (unique)
        uint[8] lootTokenIds; //these are the tokenIds that are rewarded to players, these can only be ERC1155
        // monsters NEED to have a token list of 8, there can be multiples of a token [1,1,1,1,1,1,2,2]
    }

    /// move to MAIN_WORLD_MONSTERS
    Monster[] private monster_list;

    constructor(address _loot_token){
        LOOT = IERC1155Mintable(_loot_token); // initalize ERC1155 loot contract
        assignRarity();
        chance = 88;
        rewardValue = 333333333333333333;
    }

    function isMonsterExists(uint _monster_id) external view returns (bool) {   
        return (monster_list[_monster_id].monsterId != uint(0)) ? true:false;
    }

    //// ADMIN FUNCTIONS ////
    // RANDOM index + RANDOM functions
    function setRANDOM(address _contract) public  {
        require(msg.sender == whitelistOwner);
        RANDOM = IRANDOM(_contract);
    }
    
    function setLOOT(address _contract) public {
        require(msg.sender == whitelistOwner);
        LOOT = IERC1155Mintable(_contract);
    }

    function getLootToken() public view returns (address) {
        return address(LOOT); 
    }

    function getRandomBetween(uint min, uint max) private view returns (uint) { 
        return (max - min) * (RANDOM.fullRandom() % 100) + min;
    }
    
    function setChance(uint n) public returns (uint){
        require(msg.sender == whitelistOwner);
        chance = n;
        return chance;
    }

    function setTaelRewardValue(uint n) public returns (uint) {
        require(msg.sender == whitelistOwner);
        rewardValue = n;
        return rewardValue;
    }

    function rollMultipleRandom(uint target, uint iterations) private view returns (bool) {
        bytes32 seed = RANDOM.getCurrentSeed();
        uint i = 0;
        while(i <= iterations){
            uint _result = uint(keccak256(abi.encodePacked(
                block.difficulty, 
                block.coinbase,
                block.number, 
                block.timestamp,
                gasleft(),
                msg.sender, 
                seed))) % 200;
            i++;
            if(_result != target){
                return false;
            } 
        }
        return true;
    }

    function lifeChangingRoll() external view returns (bool) {
        require(whitelist[msg.sender]==true);
        return rollMultipleRandom(200, 6);
    }

    function rollTaelReward() external view returns (uint) {
        require(whitelist[msg.sender]==true);
        if( RANDOM.randomIndex(chance) <= 8 ) {
            uint _amount = RANDOM.randomIndex(rewardValue);
            return _amount;
        } else {
            return 0;
        }
    }

    function rollCondenseTaelChanceReward() external view returns (uint) {
        require(whitelist[msg.sender]==true);
        if( RANDOM.randomIndex(chance) == 1 ) {
            uint _amount = RANDOM.randomIndex(rewardValue);
            return _amount;
        } else {
            return 0;
        }
    }

    function returnMonsterReward(uint _monsterId) external view returns (uint) {
        require(whitelist[msg.sender] == true);
        return monster_list[_monsterId].lootTokenIds[uint(rarityIndex[RANDOM.randomIndex(200)])];
    }
    //// END ADMIN FUNCTIONS ////

    //// ITEM RARITY INDEX ////
    enum rarity { Common, Uncommon, Rare, VeryRare, Earth, Legendary, Demonic, Heavenly }
    mapping(uint => rarity) private rarityIndex;

    function assignRarity() private {
        require(msg.sender == whitelistOwner);
        for(uint i = 0; i < 50; i++) {
            rarityIndex[i] = rarity.Common;
        }
        for(uint i = 50; i < 100; i++) {
            rarityIndex[i] = rarity.Uncommon;
        }
        for(uint i = 100; i < 125; i++) {
            rarityIndex[i] = rarity.Rare;
        }
        for(uint i = 125; i < 150; i++) {
            rarityIndex[i] = rarity.VeryRare;
        }
        for(uint i = 150; i < 185; i++) {
            rarityIndex[i] = rarity.Earth;
        }
        for(uint i = 185; i < 195; i++) {
            rarityIndex[i] = rarity.Legendary;
        }
        for(uint i = 195; i < 200; i++) {
            rarityIndex[i] = rarity.Demonic;
        }
        rarityIndex[200] = rarity.Heavenly;
    }

    /// MONSTER FUNCTIONS ///
    function addMonster(uint _monsterId, uint[8] memory _lootDrop) public {
        require(msg.sender == whitelistOwner);
        Monster memory babyMonster = Monster({
            monsterId: _monsterId,
            lootTokenIds: _lootDrop
        });
        monster_list.push(babyMonster);
    }
    /// END MONSTER FUNCTIONS ///

    /// LOOT FUNCTIONS ///
    function lootReward(address player,uint _tokenId) external returns (bool) {
        require(whitelist[msg.sender] == true);
        LOOT.mint(player, _tokenId, 1);
        // rollTaelReward(player);
        return true;
    }

    function playerTokenBalance(address _player, uint tokenId) external view returns (uint) {
        require(whitelist[msg.sender] == true);
        return LOOT.balanceOf(_player, tokenId);
    }

    function burnItem(address _player, uint tokenId, uint amount) external returns (bool) {
        require(whitelist[msg.sender] == true);
        LOOT.burn(_player, tokenId, amount);
        return true;
    }
    /// END LOOT FUNCTIONS ///

    /// EXPOSED TO CRAFTING FUNCTIONS
    function approveAll(address _operator, bool set) external returns (bool) {
        require(whitelist[msg.sender]== true);
        LOOT.setApprovalForAll(_operator, set);
        return set;
    }

    function transferFrom(address _from, address _to, uint256 _id, uint256 _amount) external returns (bool) {
        require(whitelist[msg.sender]== true);
        LOOT.safeTransferFrom(_from, _to, _id, _amount,"");
        return true;
    }

    function checkBatchBalance(address _account, uint[] memory _ids, uint[] memory _qty) external view returns (bool) {
        for(uint i=0; i < _ids.length; i++) {
            require(LOOT.balanceOf(_account, _ids[i]) >= _qty[i]);
        }
        return true;
    }
    


    /// get the exposed functions in the ERC1155 item contract
    

    //let LOOT contract create daily possible tael rewards, create contract holder for game treasury and pull from there by creating an interface for the gametreasury;
    // possibility of earning a tael reward is 1/200
    // stake 1000 tael for 12 intervals = put on the whitelist for taelrewards

    // temporary buffs use token id with blocktimestamp as expiration
    


}

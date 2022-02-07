// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Interfaces/ILOOT.sol";
import "../whitelisted.sol";
import "../Interfaces/IWORLDLAND.sol";
import "../Interfaces/IERC20Mintable.sol";
import "../Interfaces/IRANDOM.sol";
import "../Interfaces/IGACHA.sol";


contract WORLD_NPC is whitelist_c {
    ILOOT private LOOT;
    IWORLDLAND private WORLD;
    IERC20Mintable private spiritJade;
    IRANDOM private RANDOM;
    IGACHA private GACHA;

    struct NPC {
        uint location;
        uint[] tokenIds;
        uint[] tokenPrices;
    }

    mapping(bytes32 => NPC) private npcId;
    bytes32[] private npcIdList;

    function setLoot(address _contract) public {
        require(msg.sender == whitelistOwner);
        LOOT = ILOOT(_contract);
    }

    function setWorld(address _contract) public {
        require(msg.sender == whitelistOwner);
        WORLD = IWORLDLAND(_contract);
    }

    function setGacha(address _contract) public {
        require(msg.sender == whitelistOwner);
        GACHA = IGACHA(_contract);
    }

    function setRandom(address _contract) public {
        require(msg.sender == whitelistOwner);
        RANDOM = IRANDOM(_contract);
    }

    function setSpiritJade(address _contract) public {
        require(msg.sender == whitelistOwner);
        spiritJade = IERC20Mintable(_contract);
    }
    
    // track approval from backend
    function approveSpiritJade() public returns (bool) {
        spiritJade.approveAll(msg.sender, address(this), 2^256-1);
        return true;
    }

    function createRandomHash() private view returns (bytes32) {
        return keccak256(abi.encodePacked(RANDOM.fullRandom())); 
    }

    function addNpc(uint landId, uint[] memory _tokenIds, uint[] memory _tokenPrices) public returns (bytes32) {
        require(msg.sender == whitelistOwner);
        bytes32 _hash = createRandomHash();
        npcId[_hash] = NPC({
            location: landId,
            tokenIds: _tokenIds,
            tokenPrices: _tokenPrices
        });
        npcIdList.push(_hash);
        return _hash;
    }

    function buyFromNpc(bytes32 npcHash, uint itemIndex) public returns (bool) {
        require(WORLD.getPlayerLocation(msg.sender) == npcId[npcHash].location);
        require(spiritJade.balanceOf(msg.sender) >= npcId[npcHash].tokenPrices[itemIndex]);
        spiritJade.burn(msg.sender, npcId[npcHash].tokenPrices[itemIndex]);
        return LOOT.lootReward(msg.sender, npcId[npcHash].tokenIds[itemIndex]);
    }
    
    function sellToNpc(uint _tokenId, uint _amount) public returns (bool) {
        require(LOOT.playerTokenBalance(msg.sender, _tokenId)>=10);
        require(_amount >= 10);
        LOOT.burnItem(msg.sender, _tokenId, _amount);
        GACHA.ext_rollGachaSJ(msg.sender);
        GACHA.rollGigaGacha(msg.sender);
        return true;
    }    
    // world locations
    // NPC list
    // NPC items available
    // LOOT only   


}
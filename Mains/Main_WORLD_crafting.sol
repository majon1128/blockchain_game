// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "../Interfaces/IRANDOM.sol";
import "../Interfaces/IUNIQUE.sol";
import "../Interfaces/ILOOT.sol";
import "../whitelisted.sol";

contract WORLD_CRAFTING is whitelist_c {
    IRANDOM private RANDOM;
    ILOOT private LOOT;
    IUNIQUE private UNIQUE;

    struct Craft {
        bytes32 recipeId; // list of tokenIds that matches tokenQty keccak and encoded
        uint[] tokenQty;
        bool claimed;
    }
    
    bytes32[] private craftEventList;
    mapping(bytes32 => Craft) private craftEvent;
    mapping(address => bool) private playerCraftingStatus; // TODO make get
    mapping(address => uint) private craftingTime; // TODO make get
    mapping(address => bytes32) private playerCurrentCrafthash;

    event craftingSuccess(address player, bytes32 recipeId);
    event craftingFail(address player, bytes32 recipeId);

    function setRANDOM(address _contract) public {
        require(msg.sender == whitelistOwner); 
        RANDOM = IRANDOM(_contract);
    }
    
    function setLOOT(address _contract) public {
        require(msg.sender == whitelistOwner);
        LOOT = ILOOT(_contract);
    }

    function setUNIQUE(address _contract) public {
        require(msg.sender == whitelistOwner);
        UNIQUE = IUNIQUE(_contract);
    }

    function getPlayerCraftingStatus(address player) public view returns (bool) {
        return playerCraftingStatus[player];
    }

    function getPlayerCraftingTime(address player) public view returns (uint) {
        return craftingTime[player];
    }

    function createCraftEventHash() private view returns (bytes32) {
        return keccak256(abi.encodePacked(RANDOM.fullRandom())); 
    }

    function approveCrafting() public returns (bool) {
        return LOOT.approveAll(address(this), true);
    }

    function craftItem(uint[] memory erc1155TokenIds, uint[] memory erc1155qty) public returns (bool) {
        require(LOOT.checkBatchBalance(msg.sender, erc1155TokenIds, erc1155qty) == true);
        bytes32 _hash = createCraftEventHash();
        craftEvent[_hash].recipeId = keccak256(abi.encodePacked(erc1155TokenIds));
        craftEvent[_hash].tokenQty = erc1155qty;
        craftEvent[_hash].claimed = false;
        for(uint i=0; i < erc1155TokenIds.length; i++) {
            LOOT.transferFrom(msg.sender, address(this), erc1155TokenIds[i] , erc1155qty[i]);
        }
        playerCraftingStatus[msg.sender] = true;
        craftEventList.push(_hash);
        playerCurrentCrafthash[msg.sender] = _hash;

        craftingTime[msg.sender] = block.timestamp + (UNIQUE.getRecipeWaitTime(craftEvent[_hash].recipeId)+900);
        
        return playerCraftingStatus[msg.sender];
    }

    function finishCrafting() public {
        require(block.timestamp > craftingTime[msg.sender]);
        if ( UNIQUE.isRecipeExist(craftEvent[playerCurrentCrafthash[msg.sender]].recipeId)) {
            UNIQUE.craft(msg.sender, craftEvent[playerCurrentCrafthash[msg.sender]].recipeId);
            emit craftingSuccess(msg.sender, craftEvent[playerCurrentCrafthash[msg.sender]].recipeId);
        } else {
            emit craftingFail(msg.sender, craftEvent[playerCurrentCrafthash[msg.sender]].recipeId);
        }
        playerCurrentCrafthash[msg.sender] = bytes32(0);
        playerCraftingStatus[msg.sender] = false;
    }

    
    // craftevent
    // recipeId

}
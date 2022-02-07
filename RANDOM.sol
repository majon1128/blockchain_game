// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./@openzeppelin/contracts/access/Ownable.sol";

contract RANDOM is Ownable {
    bytes32[] private seeds;
    address private CULTI;
    address private WORLD;
    address private LOOT;
    address private UNIQUE;

    function setContracts(address _culti, address _world, address _loot, address _unique) public onlyOwner {
        CULTI = _culti;
        WORLD = _world;
        LOOT = _loot;
        UNIQUE = _unique;
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(
            block.difficulty, 
            block.coinbase,
            block.number, 
            block.timestamp,
            gasleft(),
            msg.sender, 
            seeds[getSeedsLength()-1])));
    }

    // public use to generate random seed. New random seed comes in every hour.
    function generateRandomSeed() external view returns (bytes32) {
        return keccak256(abi.encodePacked(
            block.difficulty, 
            block.coinbase,
            block.number, 
            block.timestamp,
            gasleft(),
            msg.sender, 
            seeds[getSeedsLength()-1])); 
    }

    function getCurrentSeed() external view returns (bytes32) {
        require(msg.sender == WORLD || msg.sender == LOOT || msg.sender == UNIQUE);
        return seeds[seeds.length-1];
    }

    function randomIndex(uint maxIndex) external view returns (uint) {
        return random() % maxIndex;
    }

    function fullRandom() external view returns (uint) {
        return random();
    }

    function getSeedsLength() public view returns (uint) {
        return seeds.length;
    }

    function addSeed(string memory _s) public onlyOwner {
        seeds.push(keccak256(abi.encodePacked(_s)));
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WORLD_PARTY {
    struct PlayerParty {
        address owner;
        mapping(address => bool) player;
        mapping(address => bool) allow;
        uint partyCount;
    }

    mapping(address => PlayerParty) private party;
    mapping(address => address) private playerPartyOwner;

    event notificationEvent(address player, uint eventId);

    function getPartyLeader(address _player) external view returns (address) {
        return playerPartyOwner[_player];
    }
    function isPlayerInParty(address _player) external view returns (bool) {
        return (playerPartyOwner[_player] == address(0)) ? false:true;
    }
    function getPlayerPartyCount(address _player) external view returns (uint) {
        return party[playerPartyOwner[_player]].partyCount;
    }
    function createParty() public returns (bool) {
        require(party[msg.sender].partyCount==0); 
        party[msg.sender].owner = msg.sender;
        party[msg.sender].player[msg.sender] = true;
        party[msg.sender].partyCount = 1;
        playerPartyOwner[msg.sender] == msg.sender;
        return true;
    }
    function dissolveParty() public returns (bool) {
        require(party[msg.sender].owner == msg.sender);
        party[msg.sender].owner = address(0);
        party[msg.sender].player[msg.sender] = false;
        party[msg.sender].partyCount = 0;
        return true;
    }
    function invitePlayerToParty(address player) public {
        require(party[msg.sender].partyCount<=5); //max 5 players per party
        require(playerPartyOwner[player] == address(0));
        party[msg.sender].allow[player] = true;
        emit notificationEvent(player, 1);
    }
    function joinParty(address partyOwner) public {
        require(party[partyOwner].allow[msg.sender] == true);
        party[partyOwner].player[msg.sender] = true;
        party[partyOwner].partyCount = party[partyOwner].partyCount + 1;
        playerPartyOwner[msg.sender] = partyOwner;
    }
    function leaveParty(address partyOwner) public {
        require(party[partyOwner].player[msg.sender] == true);
        party[partyOwner].player[msg.sender] = false;
        party[partyOwner].partyCount = party[partyOwner].partyCount - 1;
        playerPartyOwner[msg.sender] = address(0);
    }
}
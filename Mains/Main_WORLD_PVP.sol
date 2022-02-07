// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/utils/Context.sol";
import "../Interfaces/IRANDOM.sol";
import "../whitelisted.sol";
import "../Interfaces/IWORLDLAND.sol";
import "../Interfaces/IEVENT.sol";
import "../Interfaces/ICULTI.sol";

contract WORLD_PVP is whitelist_c {
    IWORLDLAND private WORLDLAND;
    IEVENT private EVENT;
    ICULTI private CULTI;
    IRANDOM private RANDOM;

    mapping(address => int) private reputation;
    mapping(bytes32 => PvpEvent) private pvp;
    mapping(address => address) private currentPlayerPvp;
    mapping(address => bytes32) private playerPvpHash;
    mapping(address => bool) private deadPlayer;
    uint private valueBalance;

    struct PvpEvent {
        address attacker;
        address defender;
    }

    event pvpStarts(bytes32 eventHash, address p1, address p2, uint timestamp);
    event pvpEnds(bytes32 eventHash, address p1, address p2, uint timestamp);

    /// ADMIN FUNCTIONS ///
    function setWORLDLAND(address _contract) public returns (address) {
        require(msg.sender == whitelistOwner);
        WORLDLAND = IWORLDLAND(_contract);
        return address(WORLDLAND);
    }

    function setRANDOM(address _contract) public returns (address) {
        require(msg.sender == whitelistOwner);
        RANDOM = IRANDOM(_contract);
        return address(RANDOM);
    }

    function setEVENT(address _contract) public returns (address) {
        require(msg.sender == whitelistOwner);
        EVENT = IEVENT(_contract);
        return address(EVENT);
    }

    function setCULTI(address _contract) public returns (address) {
        require(msg.sender == whitelistOwner);
        CULTI = ICULTI(_contract);
        return address(CULTI);
    }

    function getValueBalance() public view returns (uint) {
        return valueBalance;
    }
    /// END ADMIN FUNCTIONS ///

    /// direct call only
    function createPvpEventHash() private view returns (bytes32) {
        return keccak256(abi.encodePacked("pvp",RANDOM.fullRandom())); 
    }
    /// direct call only
    // Add make payable. Whoever initiates the fight needs to the cover the gas for the result of the fight. 
    function attackPlayer(address _victim) public payable {
        require(WORLDLAND.isPlayerinSameLocation(msg.sender, _victim) == true);
        require(msg.value >= 1*10**17);
        valueBalance = valueBalance + msg.value;
        
        bytes32 _hash = createPvpEventHash();
        PvpEvent memory newPvpEvent = PvpEvent({
            attacker: msg.sender,
            defender: _victim
        });
        pvp[_hash] = newPvpEvent;
        currentPlayerPvp[msg.sender] = _victim;
        currentPlayerPvp[_victim] = msg.sender;
        
        playerPvpHash[msg.sender] = _hash;
        playerPvpHash[_victim] = _hash;

        EVENT.ext_SetPvpFlag(msg.sender, _victim, true);
        emit pvpStarts(_hash, msg.sender, _victim, block.timestamp);
    }

    // orchestrate in server who wins the match
    function pvpFinish(bytes32 _hash, address _winner, address _loser) public {
        require(msg.sender == whitelistOwner);
        deadPlayer[_loser] = true;
        reputation[_winner] = reputation[_winner]-15;

        playerPvpHash[_winner] = bytes32(0);
        playerPvpHash[_loser] =  bytes32(0);

        EVENT.ext_SetPvpFlag( pvp[_hash].attacker, pvp[_hash].defender, false);

        emit pvpEnds(_hash, pvp[_hash].attacker, pvp[_hash].defender, block.timestamp);
    }

    /// direct call only
    function pvpRunAway() public {
        require(CULTI.isPlayerFasterThan(msg.sender, currentPlayerPvp[msg.sender], 2) == true);
        address player2 = currentPlayerPvp[msg.sender];
        bytes32  _hash = playerPvpHash[msg.sender];

        currentPlayerPvp[msg.sender] = address(0);
        currentPlayerPvp[player2] = address(0);

        playerPvpHash[msg.sender] = bytes32(0);
        playerPvpHash[player2] =  bytes32(0);

        EVENT.ext_SetPvpFlag(msg.sender, player2, false);
        emit pvpEnds(_hash, msg.sender, player2, block.timestamp);
    }

    function getPlayerReputation(address _player) external view returns (int) {
        return reputation[_player];
    }

    function isPlayerDead(address _player) public view returns (bool){
        return deadPlayer[_player];
    }

    // mass pvp should have 15 second intervals between attacking players
    // people might call the contract directly and will have some time before they are set to dead
    // this function is for mass pvp offchain
    function setPlayerDead(address _player) public returns (bool) {
        require(deadPlayer[_player] == false); 
        deadPlayer[_player] = true;
        return deadPlayer[_player];
    }

    // this function is for mass pvp
    /// direct call only
    function playerRespawn() public {
        require(deadPlayer[msg.sender] == true); 
        WORLDLAND.setPlayerLocation(msg.sender, 1);
    }

    function airDropPvpParticipants(address[] memory playerList) public {
        require(msg.sender == whitelistOwner);
        require(valueBalance >= 88*10**18); //minimum amount to air drop is 88 matic
        uint n = playerList.length-1;
        uint playerReward = (valueBalance-(10*10**18))/n; // cover the gas cost for the airdrop
        for(uint i = 0; i <= n; i++){
            payable(playerList[i]).transfer(playerReward);
        }
    }

}
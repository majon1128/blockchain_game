// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Interfaces/IERC721Mintable.sol";
import "../Interfaces/IRANDOM.sol";
import "../Interfaces/ICULTI.sol";
import "../Interfaces/ILOOT.sol";
import "../whitelisted.sol";
import "../Interfaces/IWORLDLAND.sol";
import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Interfaces/IGACHA.sol";
import "../Interfaces/ICULTI.sol";
import "../Interfaces/IERC20Mintable.sol";

contract WORLD_EVENTS is whitelist_c {
    IRANDOM private RANDOM;
    ICULTI private CULTI;
    ILOOT private LOOT;
    IWORLDLAND private WORLDLAND;
    IERC20 private tael;
    IGACHA private GACHA;
    IERC20 private trueQi;
    IERC20Mintable private spiritJade;
    address private GameTreasury; // this should be this contract
    address private TeamTreasury;
    address private DaoTreasury;
    address private rarityIndex;

    uint private fixedSjConversion;
    uint private constant decimals = 10**18;

    mapping(bytes32 => Game_Events) private eventInstance;
    mapping(bytes32 => address) private eventPartyMember;
    bytes32[] private eventList;
    mapping(address => bytes32) private playerLastEvent;
    mapping(address => bool) private pvpEventFlag;
    mapping(address => uint) private playerCurrentQi;
    mapping(address => bool) private condenseFlag;
    
    mapping(address => bool) private condenseWhitelist;
    bool private condenseWhitelistFlag;

    struct Game_Events {
        bytes32 event_id; //keccak256(abi.encodePacked(address, b))
        uint monster_id;
        uint reward;
        uint taelReward;
        bool complete;
        bool abandon;
        mapping(address => bool) claimed;
    }

    event eventStart(address player, uint timestamp);
    event eventEnd(address player, uint timestamp);
    event eventCondenseStart(address player, uint timestamp);
    event eventCondenseEnd(address player, uint timestamp);

    //// ADMIN FUNCTIONS //// 
    constructor() {
        fixedSjConversion = 1125001125001;
        condenseWhitelistFlag = false;
    }

    function setRANDOM(address _contract) public  {
        require(msg.sender == whitelistOwner);
        RANDOM = IRANDOM(_contract);
    }

    function setTreasuries(address _gameTreasury, address _teamTreasury, address _daoTreasury) public returns (address, address, address) {
        require(msg.sender == whitelistOwner);
        GameTreasury = _gameTreasury;
        TeamTreasury = _teamTreasury;
        DaoTreasury = _daoTreasury;
        return(GameTreasury,TeamTreasury,DaoTreasury);
    }

    function setLOOT(address _contract) public {
        require(msg.sender == whitelistOwner);
        LOOT = ILOOT(_contract);
    }

    function setCULTI(address _contract) public {
        require(msg.sender == whitelistOwner);
        CULTI = ICULTI(_contract);
    }

    function setGacha(address _contract) public {
        require(msg.sender == whitelistOwner);
        GACHA = IGACHA(_contract);
    }

    function setTrueQi(address _contract) public {
        require(msg.sender == whitelistOwner);
        trueQi = IERC20(_contract);
    }

    function setSpiritJade(address _contract) public {
        require(msg.sender == whitelistOwner);
        spiritJade = IERC20Mintable(_contract);
    }

    function setTAEL(address _contract) public {
        require(msg.sender == whitelistOwner);
        tael = IERC20(_contract);
    }

    function setWORLDLAND(address _contract) public {
        require(msg.sender == whitelistOwner);
        WORLDLAND = IWORLDLAND(_contract);
    }

    function setCondenseWhitelistFlag(bool set) public {
        require(msg.sender == whitelistOwner);
        condenseWhitelistFlag = set;
    }
    //// END ADMIN FUNCTIONS ////

  

    function ext_SetPvpFlag(address _player1, address _player2, bool set) external returns (bool) {
        require(whitelist[msg.sender] == true);
        pvpEventFlag[_player1] = set;
        pvpEventFlag[_player2] = set;
        return set;
    }

    function setPlayerQi(address player, uint qi) external returns (bool) {
        playerCurrentQi[player] = qi;
        return true;
    }

    function createRandomEventHash() private view returns (bytes32) {
        return keccak256(abi.encodePacked(RANDOM.fullRandom())); 
    }
    
    function createEventInstance(address _participants, uint _monsterId_) private returns (bytes32) {
        bytes32 instanceHash = createRandomEventHash();
        eventInstance[instanceHash].event_id = instanceHash;
        eventInstance[instanceHash].monster_id = _monsterId_;
        eventInstance[instanceHash].reward = LOOT.returnMonsterReward(_monsterId_);
        eventInstance[instanceHash].taelReward = LOOT.rollTaelReward();
        eventInstance[instanceHash].complete = false;
        eventInstance[instanceHash].abandon = false;
        eventInstance[instanceHash].claimed[_participants] = false;
        eventPartyMember[instanceHash] = _participants;
        eventList.push(instanceHash);

        return instanceHash;
    }

    function condenseEvent(address _player, uint _amount) private returns (bytes32) {
        bytes32 instanceHash = createRandomEventHash();
        eventInstance[instanceHash].event_id = instanceHash;
        eventInstance[instanceHash].monster_id = 0;
        eventInstance[instanceHash].reward = _amount;
        eventInstance[instanceHash].taelReward = LOOT.rollCondenseTaelChanceReward();
        eventInstance[instanceHash].complete = false;
        eventInstance[instanceHash].abandon = false;
        eventInstance[instanceHash].claimed[_player] = false;
        eventPartyMember[instanceHash] = _player;
        eventList.push(instanceHash);

        condenseFlag[_player] = true;
        return instanceHash;
    }

    /// need to be direct call to the contract
    /// server will keep track of the player's last event
    function getPlayerLastEvent(address _player) public view returns (bytes32) {
        require(msg.sender == whitelistOwner || whitelist[msg.sender] == true);
        return playerLastEvent[_player];
    }

    /// need to be direct call to the contract
    function isPlayerInEvent(address _player) public view returns (bool) {
        return !eventInstance[playerLastEvent[_player]].complete;
    }

    /// need to be direct call to the contract
    function playerAbandonCurrentEvent() public returns (bool) {
        eventInstance[playerLastEvent[msg.sender]].complete = true;
        eventInstance[playerLastEvent[msg.sender]].abandon = true;
        return true;
    }

    /// need to be direct call to the contract
    /// server will return _hash id for the event if the player finishes the event
    /// server will keep track of the player's last event hash and check whether its abandoned, claimed, or completed
    function claimEvent(bytes32 _hash) public returns (bool) {
        require(pvpEventFlag[msg.sender] == false);
        require(eventInstance[_hash].abandon == false);
        require(eventInstance[_hash].claimed[msg.sender] == false);
        require(condenseFlag[msg.sender] == false);
        
        eventInstance[_hash].claimed[msg.sender] = true;
        eventInstance[_hash].complete == true;

        if(eventInstance[_hash].reward != 0 ) {
            LOOT.lootReward(msg.sender, eventInstance[_hash].reward); // anti cheat, use _hash
        }
        if(eventInstance[_hash].taelReward != 0) {
            tael.transferFrom(address(this), msg.sender, eventInstance[_hash].taelReward);
        }
        
        emit eventEnd(msg.sender, block.timestamp);
        return true;
    }

    function event_getPlayerCurrentQi(address _player) external view returns (uint) {
        return playerCurrentQi[_player];
    }

    function event_useQi(address _player) external returns (uint) {
        require(playerCurrentQi[msg.sender] >= 1, "NO_MORE_QI");
        playerCurrentQi[_player] = playerCurrentQi[_player] - 1;
        return playerCurrentQi[_player];
    }

    function playerAdventure() public returns (bool) {
        require(condenseFlag[msg.sender] == false);
        require(isPlayerInEvent(msg.sender) == false);
        require(pvpEventFlag[msg.sender] == false);
        require(playerCurrentQi[msg.sender] >= 1, "NO_MORE_QI");
        GACHA.rollGigaGacha(msg.sender);
        playerCurrentQi[msg.sender] = playerCurrentQi[msg.sender]-1;
        createEventInstance(msg.sender, WORLDLAND.getRandomMonsterFromLocation(msg.sender));
        
        emit eventStart(msg.sender, block.timestamp);
        return true;
    }
    //// PLAYER EVENTS ////

    
    /// event, 1/5 chance to encounter a battle with inner demon, do this off chain and reward player with the hashid to get the condense
    function startCondense(address player, uint amount) public {
        require(msg.sender == player);
        require(trueQi.balanceOf(player) >= 888888*decimals);
        require(amount >= 888888*decimals);
        condenseEvent(player, amount);
        emit eventCondenseStart(player, block.timestamp);
    }

    function claimCondenseEvent(bytes32 _hash) public {
        if ( condenseWhitelistFlag == true) {
            require(condenseWhitelist[msg.sender] == true);
        }
        require(condenseFlag[msg.sender] == true);
        require(pvpEventFlag[msg.sender] == false);
        require(eventInstance[playerLastEvent[msg.sender]].abandon == false);
        require(eventInstance[playerLastEvent[msg.sender]].claimed[msg.sender] == false);
        require(eventPartyMember[_hash] == msg.sender);
        uint amount = eventInstance[playerLastEvent[msg.sender]].reward;
        trueQi.transferFrom(msg.sender, address(this), amount);
        spiritJade.mint(msg.sender, (amount/decimals)*fixedSjConversion);
        emit eventCondenseEnd(msg.sender, block.timestamp);
    }

}
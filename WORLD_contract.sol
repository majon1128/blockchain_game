// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./@openzeppelin/contracts/access/Ownable.sol";
import "./@openzeppelin/contracts/utils/Context.sol";
import "./@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interfaces/IERC721Mintable.sol";
import "./Interfaces/IRANDOM.sol";
import "./Interfaces/ILOOT.sol";
import "./Interfaces/ICULTI.sol";
import "./whitelisted.sol";

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

contract WorldContract is SafeMath, Ownable, whitelist_c {
    IERC20 private tael; //Make sure to change this to the token contract
    ILOOT private LOOT; 
    IRANDOM private RANDOM;
    ICULTI private CULTI;
    IERC721Mintable private LANDPARCEL;
    uint private eventCount;
    uint private constant decimals = 10**18;
    address private teamTreasury;
    address private daoTreasury;
    uint private gasPrice;

        struct Game_Events {
        bytes32 event_id; //keccak256(abi.encodePacked(address, b))
        uint monster_id;
        bool complete;
        bool abandon;
        bool claimed;
    }

    struct Land {
        uint land_id;
        uint tokenId;
        uint x;
        uint y;
        uint[] monsterIds;
        uint[] resource;
        address owner;
    }

    uint[108886] private securityDepositAmount;
    uint[108886] private landTokenMap; // index == tokenId, this needs to be prefilled

    struct Location {
        uint x;
        uint y;
    }

    struct PlayerParty {
        address owner;
        mapping(address => bool) player;
        mapping(address => bool) allow;
        uint partyCount;
    }

    uint private biannualTaxEvent;
    bytes32[] private eventList;
    mapping(address => bytes32) private playerLastEvent;
    mapping(bytes32 => Game_Events) private eventInstance;
    mapping(bytes32 => address[]) private eventParticipants;
    mapping(address => Location) private playerLocation;
    mapping(address => uint) private playerLastMoveTurn;
    mapping(address => PlayerParty) private party;
    mapping(address => address) private playerPartyOwner;
    mapping(address => uint) private playerReputation;

    Land[108886] private theRealmOfDao;

    
    
    
    event notificationEvent(address player, uint eventId);
    // party invite notification eventId = 1

    /// ADMIN FUNCTIONS ///
    constructor() {
        assignRarity();
    }
    enum rarity { Common, Uncommon, Rare, VeryRare, Earth, Legendary, Demonic, Heavenly }
    mapping(uint => rarity) private rarityIndex;
    function setTreasuries(address _teamTreasury, address _daoTreasury) public onlyOwner {
        _teamTreasury = _teamTreasury;
        daoTreasury = _daoTreasury;
    }
    function setLOOT(address _contract) public onlyOwner {
        LOOT = ILOOT(_contract);
    }
    function setCULTI(address _contract) public onlyOwner {
        CULTI = ICULTI(_contract);
    }
    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : -x;
    }
    function setRANDOM(address _contract) public onlyOwner {
        RANDOM = IRANDOM(_contract);
    }
    function setTAEL(address _contract) public onlyOwner {
        tael = IERC20(_contract);
    }
    
    function assignRarity() private onlyOwner {
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


    /// END ADMIN FUNCTIONS ///
    /// EVENT FUNCTIONS ///
    // needs to be orchestrated along with server to check if event is passed or not

    /// need to emit event instance creation, then orchestrate notification to addresses of party and allow them to join the instance
    function setEventComplete(bytes32 _hash) public onlyOwner {
        eventInstance[_hash].complete = true;
    }

    function createRandomEventHash() private view returns (bytes32) {
        return keccak256(abi.encodePacked(RANDOM.fullRandom())); 
    }
    function rollRandom(uint target, uint iterations) public view returns (bool) {
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
// create event instance -> roll random -> send to instance lootpool
// if player is instance, cannot create instance, must finish current instance

// lootpool claim after instance is finished


    function createEventInstance(address[] memory _participants, uint _monsterId) private {
        bytes32 instanceHash = createRandomEventHash();
        eventInstance[instanceHash] = Game_Events({
            event_id: instanceHash,
            monster_id: _monsterId,
            complete: false,
            abandon: false,
            claimed: false
        });
        eventParticipants[instanceHash] = _participants;
        eventList.push(instanceHash);
    }

    function getPlayerLastEvent() public view returns (bytes32) {
        return playerLastEvent[msg.sender];
    }

    function isPlayerInEvent() public view returns (bool) {
        return eventInstance[playerLastEvent[msg.sender]].complete;
    }

    function playerAbandonCurrentEvent() public returns (bool) {
        eventInstance[playerLastEvent[msg.sender]].complete = true;
        eventInstance[playerLastEvent[msg.sender]].abandon = true;
        return true;
    }

    function claimEvent() public returns (bool) {
        require(eventInstance[playerLastEvent[msg.sender]].abandon == false);
        require(eventInstance[playerLastEvent[msg.sender]].complete == true);
        require(eventInstance[playerLastEvent[msg.sender]].claimed == false);
        LOOT.lootReward(msg.sender,
                        uint(rarityIndex[RANDOM.randomIndex(200)]));
        eventInstance[playerLastEvent[msg.sender]].claimed = false;
        return true;
    }
    /// END EVENT FUNCTIONS ///

    /// LAND FUNCTIONS ///
    /// READ FIRST
    /// repeating 3 times for each realm looks stupid, but we want the user to know that they are registering for something special in the contract
    function securityPrepay(uint landId,uint _tokenId, uint _amount) public {
        require(LANDPARCEL.ownerOf(_tokenId) == msg.sender);
        require(_amount >= biannualTaxEvent);
        require(theRealmOfDao[landId].tokenId == _tokenId);
        require(tael.balanceOf(msg.sender)>= _amount);
        tael.transfer(address(this), _amount);
        securityDepositAmount[landId] = _amount;
        
    }
    
    uint[] public unpaidDepositsLandIds;
    /// need to consume the taels in batches
    function consumeSecurityDeposits(uint minIndex, uint maxIndex) public onlyOwner {
        uint payOut = 0;
        for(uint i = minIndex; i <= maxIndex; i++){
            if(securityDepositAmount[i] >= biannualTaxEvent){
                securityDepositAmount[i] = safeSub(securityDepositAmount[i] , biannualTaxEvent);
                payOut = payOut + biannualTaxEvent;
            } else {
                unpaidDepositsLandIds.push(i);
            }
        }   
        tael.transferFrom(address(this), teamTreasury, safeDiv(payOut,2));
        tael.transferFrom(address(this), daoTreasury, safeDiv(payOut,2));
    }

    function evict(uint _landId) public onlyOwner returns (uint) {
        theRealmOfDao[_landId].owner = address(0);
        uint newTokenId = LANDPARCEL.mint(teamTreasury);
        landTokenMap[_landId] = newTokenId;
        return newTokenId;
    }
    /// evict ownership function and mint a new token that will map to the landtokenmap with land id and new tokenid IF the token owner is not equals to 0
    
    function setTaxAmount(uint _amount) public onlyOwner returns (bool) {
        biannualTaxEvent = _amount*decimals;
        return true;
    }
    function getTaxAmount() public view onlyOwner returns (uint) {
        return biannualTaxEvent;
    }
    function resetunpaidDepositsLandIds() public onlyOwner {
        delete unpaidDepositsLandIds;
    }

    function registerLand(uint _tokenId, uint landId) public {
        require(LANDPARCEL.ownerOf(_tokenId)==msg.sender); // 0 - 88,888 = mortal realm, 88,889 - 98,888 = demon realm, 98,889 - 108,887 = heavenly realm
        require(landTokenMap[landId]==_tokenId);
        require(theRealmOfDao[landId].tokenId == _tokenId);
        theRealmOfDao[landId].owner = msg.sender;
    }


    function setLandData(uint landId, uint _tokenId, uint _x, uint _y, uint[] memory _monsterIds, uint[] memory resource) public onlyOwner {
        require(landId <= 88888);
        require(landTokenMap[landId]==_tokenId);
        Land memory setLand = Land({
            land_id: landId,
            tokenId: _tokenId,
            x: _x,
            y: _y,
            monsterIds:_monsterIds,
            resource: resource,
            owner: msg.sender
        });
        theRealmOfDao[landId] = setLand;
    }

    /// END LAND FUNCTIONS ///

    /// LOCATION FUNCTIONS ///
    function setPlayerLocation(address player, uint _x, uint _y) public onlyOwner returns (bool) {
        playerLocation[player].x = _x;
        playerLocation[player].y = _y;
        return true;
    }

    function playerMove(uint _x, uint _y) public returns (bool)  {
        uint currentTurn = CULTI.getCurrentTurn();
        require(playerLastMoveTurn[msg.sender] != currentTurn);
        uint playerSpeed = CULTI.returnPlayerSpeed(msg.sender);
        uint moveAmount = safeAdd(uint(abs(int(playerLocation[msg.sender].x) - int(_x))),uint(abs(int(playerLocation[msg.sender].y) - int(_y))));
        require(playerSpeed >= moveAmount);
        playerLocation[msg.sender].x = _x;
        playerLocation[msg.sender].y = _y;
        playerLastMoveTurn[msg.sender] = currentTurn;
        return true;
    }
    // x, y
    function getPlayerLocation(address player) public view returns (uint, uint){
        return (playerLocation[player].x, playerLocation[player].y);
    }

    function getPlayerCurrentLandLocation(address player) external view returns (uint) {
        
    }

    /// END LOCATION FUNCTIONS ///

    /// PARTY FUNCTIONS ///
    function createParty() public returns (bool) {
        require(party[msg.sender].partyCount==0); 
        party[msg.sender].owner = msg.sender;
        party[msg.sender].player[msg.sender] = true;
        party[msg.sender].partyCount = 1;
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
    /// END PARTY FUNCTIONS ///

    // function randomEncounter();
    
    /// random encounters
    /// reputation
    /// mariage
    /// monsters
}

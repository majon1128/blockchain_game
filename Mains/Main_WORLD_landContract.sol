// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Interfaces/IERC721Mintable.sol";
import "../Interfaces/IRANDOM.sol";
import "../Interfaces/ICULTI.sol";
import "../whitelisted.sol";
import "../Interfaces/ICULTI.sol";
import "../Interfaces/IEVENT.sol";

contract WORLD_LAND is whitelist_c {
    IERC721Mintable private LANDPARCEL;
    ICULTI private CULTI;
    IEVENT private EVENT;
    IERC20 private tael;
    IRANDOM private RANDOM;
    address private TeamTreasury;
    address private DaoTreasury;
    address private GameTreasury;
    uint private constant decimals = 10**18;
    uint[] public unpaidDepositsLandIds;

    struct Land {
        uint land_id;
        uint tokenId;
        uint x;
        uint y;
        uint[] monsterIds;
        uint[6] resource; /// max 6 resources per land
        uint size;
        address owner;
    }

    mapping(address => uint) private playerLocation; //playerlocation is landid
    mapping(address => uint) private playerLastMoveTurn;

    Land[108886] private theRealmOfDao;
    uint[108886] private landTokenMap;
    uint private biannualTaxEvent;
    uint[108886] private securityDepositAmount;

    /// ADMIN FUNCTIONS ///
    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : -x;
    }
    function setLANDPARCEL(address _contract) public returns (address) {
        require(msg.sender == whitelistOwner);
        LANDPARCEL = IERC721Mintable(_contract);
        return address(LANDPARCEL);
    }
    function setCULTI(address _contract) public returns (address) {
        require(msg.sender == whitelistOwner);
        CULTI = ICULTI(_contract);
        return address(CULTI);
    }
    function setTAEL(address _contract) public returns (address) {
        require(msg.sender == whitelistOwner);
        tael = IERC20(_contract);
        return address(tael);
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

    function setTreasuries(address _gameTreasury, address _teamTreasury, address _daoTreasury) public returns (address, address, address) {
        GameTreasury = _gameTreasury;
        TeamTreasury = _teamTreasury;
        DaoTreasury = _daoTreasury;
        return(GameTreasury,TeamTreasury,DaoTreasury);
    }
    /// END ADMIN FUNCTIONs ///

    /// TAX FUNCTIONS ///
    function securityPrepay(uint landId,uint _tokenId, uint _amount) public {
        require(LANDPARCEL.ownerOf(_tokenId) == msg.sender);
        require(_amount >= biannualTaxEvent);
        require(theRealmOfDao[landId].tokenId == _tokenId);
        require(tael.balanceOf(msg.sender)>= _amount);
        tael.transfer(address(this), _amount);
        securityDepositAmount[landId] = securityDepositAmount[landId] + _amount;
        
    }
    
    /// need to consume the taels in batches
    function consumeSecurityDeposits(uint minIndex, uint maxIndex) public {
        require(msg.sender==whitelistOwner);
        uint payOut = 0;
        for(uint i = minIndex; i <= maxIndex; i++){
            if(securityDepositAmount[i] >= biannualTaxEvent){
                securityDepositAmount[i] = securityDepositAmount[i] - biannualTaxEvent;
                payOut = payOut + biannualTaxEvent;
            } else {
                unpaidDepositsLandIds.push(i);
            }
        }   
        tael.transferFrom(address(this), TeamTreasury, payOut/2);
        tael.transferFrom(address(this), DaoTreasury, payOut/2);
    }

    function evict(uint _landId) public returns (uint) {
        require(msg.sender == whitelistOwner);
        theRealmOfDao[_landId].owner = address(0);
        uint newTokenId = LANDPARCEL.mint(TeamTreasury);
        landTokenMap[_landId] = newTokenId;
        theRealmOfDao[_landId].tokenId = newTokenId;
        return newTokenId;
    }
    /// evict ownership function and mint a new token that will map to the landtokenmap with land id and new tokenid IF the token owner is not equals to 0
    
    function setTaxAmount(uint _amount) public returns (bool) {
        require(msg.sender == whitelistOwner);
        biannualTaxEvent = _amount*decimals;
        return true;
    }
    function getTaxAmount() public view returns (uint) {
        require(msg.sender == whitelistOwner);
        return biannualTaxEvent;
    }
    function resetunpaidDepositsLandIds() public {
        require(msg.sender == whitelistOwner);
        delete unpaidDepositsLandIds;
    }
    /// END TAX FUNCTIONS ///

    /// LAND FUNCTIONS ///
    function registerLand(uint _tokenId, uint landId) public {
        require(LANDPARCEL.ownerOf(_tokenId)==msg.sender); // 0 - 88,888 = mortal realm, 88,889 - 98,888 = demon realm, 98,889 - 108,887 = heavenly realm
        require(landTokenMap[landId]==_tokenId);
        require(theRealmOfDao[landId].tokenId == _tokenId);
        theRealmOfDao[landId].owner = msg.sender;
    }

    function setLandData(uint landId, uint _tokenId, uint _x, uint _y, uint _size,uint[] memory _monsterIds, uint[6] memory _resource) public {
        require(msg.sender == whitelistOwner);
        require(landTokenMap[landId]==_tokenId);
        Land memory setLand = Land({
            land_id: landId,
            tokenId: _tokenId,
            x: _x,
            y: _y,
            monsterIds:_monsterIds,
            resource: _resource,
            size: _size,
            owner: msg.sender
        });
        theRealmOfDao[landId] = setLand;
    }

    function transferLandOwnership(uint _landId, uint _tokenId, address _to) public returns (bool) {
        require(LANDPARCEL.ownerOf(_tokenId)==msg.sender);
        require(theRealmOfDao[_landId].owner==msg.sender);
        require(theRealmOfDao[_landId].tokenId==_tokenId);
        if(!LANDPARCEL.isApprovedForAll(msg.sender, address(this))) {
            LANDPARCEL.setApprovalForAll(address(this), true);
        }
        LANDPARCEL.safeTransferFrom(msg.sender, _to, _tokenId);
        theRealmOfDao[_landId].owner = _to;
        require(LANDPARCEL.ownerOf(_tokenId) == _to);
        return true;
    }

    function getLandOwner(uint landId) public view returns (address) {
        return theRealmOfDao[landId].owner;
    }

    function returnLandResourceById(uint landId) external view returns (uint[6] memory) {
        return theRealmOfDao[landId].resource;
    }
    /// END LAND FUNCTIONS

    /// PLAYER LOCATION FUNCTIONS ///
    function playerMove(uint _targetLandId) public returns (bool)  {
        EVENT.event_useQi(msg.sender);
        uint currentTurn = CULTI.getCurrentTurn();
        require(playerLastMoveTurn[msg.sender] != currentTurn);
        uint playerSpeed = CULTI.returnPlayerSpeed(msg.sender);
        uint moveAmount = uint(abs(int(theRealmOfDao[playerLocation[msg.sender]].x) - int(theRealmOfDao[_targetLandId].x))) + uint(abs(int(theRealmOfDao[playerLocation[msg.sender]].y) - int(theRealmOfDao[_targetLandId].y)));
        require(playerSpeed >= moveAmount);
        playerLocation[msg.sender] = theRealmOfDao[_targetLandId].land_id;
        playerLastMoveTurn[msg.sender] = currentTurn;
        return true;
    }

    function setPlayerLocation(address _player, uint _landId) external returns (uint) {
        playerLocation[_player] = _landId;
        return playerLocation[_player];
    }

    function getPlayerLocation(address player) external view returns (uint){
        return playerLocation[player];
    }

    function isPlayerinSameLocation(address _player1, address _player2) external view returns (bool) {
        return playerLocation[_player1] == playerLocation[_player2];
    }

    function getRandomMonsterFromLocation(address player) external view returns (uint) {
        uint monsterIndex = RANDOM.randomIndex(theRealmOfDao[playerLocation[player]].monsterIds.length);
        return theRealmOfDao[playerLocation[player]].monsterIds[monsterIndex];
    }
    /// END PLAYER LOCATION FUNCTIONS ///
}

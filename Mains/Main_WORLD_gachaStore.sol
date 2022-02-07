// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Interfaces/IRANDOM.sol";
import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../whitelisted.sol";
import "../Interfaces/ILOOT.sol";
import "../Interfaces/IERC20Mintable.sol";


contract WORLD_GACHA is whitelist_c {
    IRANDOM private RANDOM;
    IERC20 private tael;
    IERC20 private spiritJade;
    ILOOT private LOOT;
    uint private constant decimals = 10**18;

    uint private sj_GachaPrice = 118*decimals;
    uint private tael_GachaPrice = 8*decimals;

    uint private taelBalance;
    uint private sjBalance;

    address private GameTreasury; // this should be the event contract
    address private TeamTreasury;
    address private DaoTreasury;

    mapping(address => uint) tokenPlayerReward;
    mapping(address => uint) gigaGachaReward;

    uint[] private tokenGachaList;
    uint[] private lifeChangingTokens; // since these are not crafted items, they will always be ERC1155

    function setTokens(address taelContract, address spiritJadeContract) public returns (address, address) {
        require(msg.sender == whitelistOwner);
        tael = IERC20(taelContract);
        spiritJade = IERC20(spiritJadeContract);
        return(address(tael), address(spiritJade));
    }

    function setRANDOM(address _contract) public returns (address){
        require(msg.sender == whitelistOwner);
        RANDOM = IRANDOM(_contract);
        return address(RANDOM);
    }

    function setLOOT(address _contract) public returns (address) {
        require(msg.sender == whitelistOwner);
        LOOT = ILOOT(_contract);
        return address(LOOT);
    }

    function addToGacha(uint _tokenId) public returns (uint) {
        require(msg.sender == whitelistOwner);
        tokenGachaList.push(_tokenId);
        return tokenGachaList[tokenGachaList.length-1];
    }

    function addUltraMegaRareItem(uint _tokenId) public {
        require(msg.sender == whitelistOwner);
        lifeChangingTokens.push(_tokenId);
    }

    function approveTael() public returns (bool) {
        return tael.approve(address(this), 2**256-1);
    }

    function approveSJ() public returns (bool) {
        return spiritJade.approve(address(this), 2**256-1);
    }

    function transferPayOuts() public {
        require(msg.sender == whitelistOwner);
        require(taelBalance >= 8*decimals);
        uint gameTreasuryPayOut = taelBalance/2;
        uint teamTreasuryPayOut = gameTreasuryPayOut/2;
        uint daoTreasuryPayOut = gameTreasuryPayOut/2;

        tael.transferFrom(address(this), GameTreasury, gameTreasuryPayOut);
        tael.transferFrom(address(this), TeamTreasury, teamTreasuryPayOut);
        tael.transferFrom(address(this), DaoTreasury, daoTreasuryPayOut);
    }

    // direct call only
    function rollGachaSJ() public {
        require(spiritJade.balanceOf(msg.sender)>=sj_GachaPrice);
        spiritJade.transferFrom(msg.sender, address(this), sj_GachaPrice);
        tokenPlayerReward[msg.sender] = tokenGachaList[RANDOM.randomIndex(tokenGachaList.length-1)];
        sjBalance = sjBalance+sj_GachaPrice;
    }

    // direct call only
    function rollGachaTAEL() public {
        require(tael.balanceOf(msg.sender)>=tael_GachaPrice);
        tael.transferFrom(msg.sender, address(this), tael_GachaPrice);
        tokenPlayerReward[msg.sender] = tokenGachaList[RANDOM.randomIndex(tokenGachaList.length-1)];
        taelBalance = taelBalance+tael_GachaPrice;
        if( LOOT.lifeChangingRoll() ){
            gigaGachaReward[msg.sender] = lifeChangingTokens[RANDOM.randomIndex(lifeChangingTokens.length-1)];
        }
    }

    /// need to be from events.sol
    function claimBox(address _player) public {
        if(tokenPlayerReward[_player] != 0){
            LOOT.lootReward(_player, tokenPlayerReward[_player]);
            tokenPlayerReward[_player] = 0;
        }
    }

    /// roll with events.sol
    function rollGigaGacha(address _player) external {
        require(whitelist[msg.sender] == true);
        if( LOOT.lifeChangingRoll() ){
            gigaGachaReward[_player] = lifeChangingTokens[RANDOM.randomIndex(lifeChangingTokens.length-1)];
        }
    }

    function claimGigaBox(address _player) public {
        if(gigaGachaReward[_player] != 0) {
            LOOT.lootReward(_player, gigaGachaReward[_player]);
            gigaGachaReward[_player] = 0;
            IERC20Mintable(address(spiritJade)).mint(_player, 8);
        }
    }

    function ext_rollGachaSJ(address player) external returns (bool) {
        require(whitelist[msg.sender] == true);
        tokenPlayerReward[player] = tokenGachaList[RANDOM.randomIndex(tokenGachaList.length-1)];
        sjBalance = sjBalance+sj_GachaPrice;
        return true;
    }

}
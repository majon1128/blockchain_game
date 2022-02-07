// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../@openzeppelin/contracts/access/Ownable.sol";
import "../Interfaces/IERC20Mintable.sol";
import "../Interfaces/IStaking.sol";
import "../Interfaces/IRANDOM.sol";

contract TaelStaking is Ownable {
    IERC20 private tael ; //Make sure to change this to the token contract
    IRANDOM private RANDOM;
    IERC20Mintable private spiritJade;
    IERC20Mintable private veTAEL;
    IStaking private STAKE;
    address private GameTreasury; // this should be a gnosis safe
    address private TeamTreasury;
    address private DaoTreasury;

    uint constant public decimals = 10**18;
    uint constant public _recycle = 12;
    uint constant public _stake = _recycle*2;
    uint constant public _stake_recycle = _stake*2;
    uint constant public day = 86400;
    uint constant public month = 30;
    uint private earnMultiplier = 1;
    uint private recycleRoyalties = 10; // 1 divided by .1 (10%) = 10

    struct Ticket {
        address depositor;
        bool isRecycled;
        bool isExpired;
        uint taelDeposit;
        uint remainingBalance;
        uint sjPerSecond;
        uint startTime;
        uint endTime;
        uint lastCheckIn;
    }

    mapping(address => uint) private stakeCountByAddress;

    Ticket[] private promissoryNote; // these are 1 index : 1 ids to ERC721 ids

    event taelRecyleEvent(uint _date, address indexed _player, uint amount);
    event taelStakeRecyleEvent(uint _date, address indexed _player, uint amount);

    /// ADMIN FUNCTIONS ///
    function setTreasuries(address _gameTreasury, address _teamTreasury, address _daoTreasury) public returns (address, address, address) {
        GameTreasury = _gameTreasury;
        TeamTreasury = _teamTreasury;
        DaoTreasury = _daoTreasury;
        return(GameTreasury,TeamTreasury,DaoTreasury);
    }

    function getRecycleRoyalties() public view returns (uint) {
        return recycleRoyalties;
    }

    function setRecycleRoyalties(uint royaltyPercentage) public onlyOwner {
        recycleRoyalties = royaltyPercentage;
    }

    function getEarnMultiplier() public view returns (uint) {
        return earnMultiplier;
    }

    function setEarnMultiplier(uint multiplier) public onlyOwner {
        earnMultiplier = multiplier;
    }
    /// END ADMIN FUNCTIONS ///

    /// Staking functions ///
    function createNote(uint depositAmount, uint _intervals) private returns (uint) {
        require(tael.balanceOf(msg.sender) >= 1);
        require(depositAmount>= 1*decimals);
        require(_intervals == 3 || _intervals == 6 || _intervals == 9 || _intervals == 12);   
        if(stakeCountByAddress[msg.sender] == 0) {
            require(depositAmount>=50*decimals);
            if(depositAmount >= 50*decimals) {
                veTAEL.mint(msg.sender, 1*decimals);
            }
        } else if(depositAmount >= 1000*decimals) {
            veTAEL.mint(msg.sender, 1*decimals);
        }
        stakeCountByAddress[msg.sender] = stakeCountByAddress[msg.sender]+1;

        tael.transfer(address(this), depositAmount);
        Ticket memory newNote = Ticket({
            depositor: msg.sender,
            isRecycled: false,
            isExpired: false,
            taelDeposit: depositAmount,
            remainingBalance: depositAmount*_stake,
            sjPerSecond: (depositAmount * _stake) / (12*month*day),
            startTime: block.timestamp + 120,
            endTime: block.timestamp  + (_intervals*month*day),
            lastCheckIn: block.timestamp + 120
        });
        uint _tokenId = STAKE.mint(msg.sender);
        promissoryNote[_tokenId] = newNote;
        require(STAKE.ownerOf(_tokenId) == msg.sender);
        return _tokenId; // either a bool or an event emit, convert this to event later
    }

    function claimNoteRewards(uint _tokenId) public returns (bool) {
        require(STAKE.ownerOf(_tokenId)==msg.sender, "CLAIMER IS NOT OWNER");
        require(promissoryNote[_tokenId].isExpired == false, "EXPIRED");
        require(block.timestamp >= promissoryNote[_tokenId].startTime, "PROMISSORY NOT ACTIVE");
        require(promissoryNote[_tokenId].remainingBalance >= 1, "NO MORE BALANCE");

        uint rewards = (promissoryNote[_tokenId].sjPerSecond * (block.timestamp - promissoryNote[_tokenId].lastCheckIn)) * earnMultiplier;
        
        promissoryNote[_tokenId].lastCheckIn = block.timestamp;

        if( promissoryNote[_tokenId].remainingBalance >= rewards) {
            promissoryNote[_tokenId].remainingBalance = promissoryNote[_tokenId].remainingBalance - rewards;
            spiritJade.mint(msg.sender, rewards);
        } else if (promissoryNote[_tokenId].remainingBalance <= rewards) {
            spiritJade.mint(msg.sender, (promissoryNote[_tokenId].remainingBalance * earnMultiplier));
            promissoryNote[_tokenId].isExpired = true;
        }
        return true;
    }

    /// normal 
    function lanternToFortuneTael(uint _amount) public {
        require(tael.balanceOf(msg.sender) >= 1*decimals);
        require(_amount >= 1*decimals);
        uint teamRoyalties = _amount / recycleRoyalties;
        uint depositRemaining = _amount - teamRoyalties;
        tael.transfer(TeamTreasury, teamRoyalties);
        tael.transfer(GameTreasury, depositRemaining);
        spiritJade.mint(msg.sender, (_amount*_recycle * earnMultiplier));
        // event emit on recycleTael 
        emit taelRecyleEvent(block.timestamp, msg.sender, _amount);
    }

    /// Degen
    function lanternToFateTael(uint _amount) public {
        require(tael.balanceOf(msg.sender) >= 1*decimals);
        require(_amount >= 1*decimals);
        uint rngTAEL = getRandomBetween(1, _recycle*2);
        uint teamRoyalties = _amount / recycleRoyalties;
        uint depositRemaining = _amount - teamRoyalties;
        tael.transfer(TeamTreasury, teamRoyalties);
        tael.transfer(GameTreasury, depositRemaining);
        spiritJade.mint(msg.sender, (_amount*rngTAEL) * earnMultiplier);
        // event emit on recycleTael 
        emit taelRecyleEvent(block.timestamp, msg.sender, _amount);
    }

    function stake(uint _depositAmount, uint _months) public returns (uint) {
        return createNote(_depositAmount, _months);
    }

    /// Stake and recycle, the tael will be split into 3 to all the treasuries
    function stakeAndRecycle(uint _depositAmount, uint _intervals) public returns (uint) {
        uint _tokenId = createNote(_depositAmount, _intervals);
        promissoryNote[_tokenId].isRecycled == true;
        promissoryNote[_tokenId].sjPerSecond = (promissoryNote[_tokenId].taelDeposit * _stake_recycle) / (12*month*day);
        uint teamRoyalties = (_depositAmount / recycleRoyalties)-3; // prevent overflow if division goes over balance of the balance of the SC
        uint royaltyPayout = teamRoyalties / 3; // this is hard coded, immutable
        tael.transferFrom(address(this), TeamTreasury, royaltyPayout); 
        tael.transferFrom(address(this), GameTreasury, royaltyPayout); 
        tael.transferFrom(address(this), DaoTreasury , royaltyPayout); 
        emit taelStakeRecyleEvent(block.timestamp, msg.sender, _depositAmount);
        return _tokenId;
    }

    function withdrawExpiredNote(uint _tokenId) public {
        require(STAKE.ownerOf(_tokenId)==msg.sender);
        require(promissoryNote[_tokenId].isRecycled == false);
        require(promissoryNote[_tokenId].isExpired == true, "EXPIRED");
        require(promissoryNote[_tokenId].remainingBalance == 0, "BALANCE REMAINING");
        require(block.timestamp >= promissoryNote[_tokenId].endTime, "PROMISSORY NOT EXPIRED");
        require(tael.balanceOf(address(this)) >= promissoryNote[_tokenId].taelDeposit);

        tael.transferFrom(address(this), msg.sender,promissoryNote[_tokenId].taelDeposit); 
        promissoryNote[_tokenId].taelDeposit = 0;
    }

    function getRandomBetween(uint min, uint max) public view returns (uint) {
        return (((max - min) * (RANDOM.fullRandom() % 100)) + min);
    }
    /// End Staking functions ///

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Interfaces/IRING.sol";
import "../whitelisted.sol";
import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WORLD_RELATIONSHIPS is whitelist_c {
    IRING private RINGS;
    IERC20 private tael;

    address private GameTreasury; 
    address private TeamTreasury;
    address private DaoTreasury;

    uint decimals = 10**18;

    mapping(address => uint) public proposal;

    event proposalEvent(address proposer, address proposee, uint tokenId);
    event proposalChoice(address proposer, address proposee, uint tokenId, bool choice);
    
    /// ADMIN FUNCTIONS ///
    function setRINGS(address _contract) public {
        require(msg.sender == whitelistOwner);
        RINGS = IRING(_contract);
    }

    function setTael(address _contract) public {
        require(msg.sender == whitelistOwner);
        tael = IERC20(_contract);
    }
    
    function setTreasuries(address _gameTreasury, address _teamTreasury, address _daoTreasury) public returns (address, address, address) {
        GameTreasury = _gameTreasury;
        TeamTreasury = _teamTreasury;
        DaoTreasury = _daoTreasury;
        return(GameTreasury,TeamTreasury,DaoTreasury);
    }
    /// END ADMIN FUNCTIONS ///

    function approveTael() private {
        tael.approve(address(this), 2^256-1);
    }

    function createRingSet() public {
        require(tael.balanceOf(msg.sender) >= 99*decimals);
        uint gameTreasuryAmount = (99*decimals)/2;
        tael.transfer(GameTreasury, gameTreasuryAmount);
        tael.transfer(TeamTreasury, gameTreasuryAmount/2);
        tael.transfer(DaoTreasury, gameTreasuryAmount/2);

        RINGS.createPair(msg.sender);
    }

    function divorceRingSet(uint ringId) public {
        require(tael.balanceOf(msg.sender) >= 111*decimals);
        uint gameTreasuryAmount = (111*decimals)/2;
        tael.transfer(GameTreasury, gameTreasuryAmount);
        tael.transfer(TeamTreasury, gameTreasuryAmount/2);
        tael.transfer(DaoTreasury, gameTreasuryAmount/2);

        RINGS.divorcePair(ringId);
    }

    function propose(address proposee, uint _ringId) public {
        require(RINGS.ownerOf(_ringId)==msg.sender);
        require(proposal[proposee]==0, "PROPOSEE_EXISTING_PROPOSAL");
        RINGS.setApprovalForAll(address(this), true);
        
        proposal[proposee] = _ringId;
        emit proposalEvent(msg.sender, proposee, _ringId);
    }

    function answerProposal(bool _choice) public {
        require(proposal[msg.sender] != 0, "NO_PROPOSALS");
        address _proposer = RINGS.ownerOf(proposal[msg.sender]);
        if( _choice == true){
            RINGS.safeTransferFrom(_proposer, msg.sender, proposal[msg.sender]);
            proposal[msg.sender] = 0;
        } else {
            proposal[msg.sender] = 0;
        }
        emit proposalChoice(_proposer, msg.sender, proposal[msg.sender], _choice);
    }
}
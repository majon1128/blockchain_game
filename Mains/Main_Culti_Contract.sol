// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/// TODO, ADD MATIC BALANCE TO EVERYTHING

import "../@openzeppelin/contracts/access/Ownable.sol";
import "../Interfaces/IERC20Mintable.sol";
import "../Interfaces/ILOOT.sol";
import "../Interfaces/IRANDOM.sol";
import "../Interfaces/IEVENT.sol";
import "../whitelisted.sol"; 

contract CultiContract is whitelist_c{
    // constant Variables
    IERC20Mintable private trueQi ; //Make sure to change this to the token contract
    IERC20Mintable private spiritJade;
    IERC20Mintable private tael;
    ILOOT private LOOT;
    IRANDOM private RANDOM;
    IEVENT private EVENT;

    uint constant private decimals = 10**18;
    uint private fixedSjConversion;

    uint private contractBalance;

    constructor() {
        fixedSjConversion = 1125001125001;
        gasPrice = 100000000000;
    }

    ///// MAPPINGS AND VARIABLES /////
    uint public worldBreakThroughCap; // the max path level cultivators can achieve before worldbreakthrough
    uint public requiredAmountCandidates; // required amount of cultivators needed to do world breakthrough
    address[] private worldBreakThroughCandidates; // List of players that have reach the level cap to trigger breakthrough and have registered
    mapping(address => uint) public playerCheckIn; // Last time user has cultivated. Cheaper to have global map instead of inside struct
    mapping(address => uint) public playerLastTurn; // maps the current turn into the player's turn on hitting the cultivate() button
    mapping(address => Cultivator) public cultivatorPlayer; // map the struct to an address
    mapping(address => mapping(uint => Learnable)) private learnableItems; // mapping and struct for item contract
    mapping(address => uint[]) public playerDestinies;
    DefaultCultivator public initialCultivator; // default player template
    Path[] public paths; // list of paths, we can retroactively add as many paths as we want
    //should we do mapping on path instead? mapping(string=> Path) private PathofDaos
    uint private currentTurn;
    uint[] private destinyIds;

    mapping(address => bool) private cultivateWhitelist;
    bool private cultivateWhitelistFlag;
    
    ///// STRUCTS /////
    struct Path {
        string pathName;
        uint pathId;
        uint itemRequirements;
        uint[] culti_rate; // XP rate per second
        uint[] bottleNecks; // cumulative xp
        uint[] pathLevel;
        uint[] pathRewards; // wtf is path rewards // path rewards is the player stat points reward
        //add more later, figure out how to work with arrays in struct and how to insert into the array in the struct
        //should we be adding attributes to paths
         //base stat modifiers, should be used whenever a major level break through is reached

    }

    struct DefaultCultivator {
        string playerPathName;
        uint playerPathId;
        uint[] playerBaseStats;
        uint[] spiritualRoot;
    }

    /// use this struct to keep track of player progress on the CULTI circle
    struct Cultivator {
        address playerAddress;
        // since mappings aren't technically keeping track of the mapped variable,
        // we need this for convenience later when we want to scroll through the players later and it will be easy to list all players with this variable
        string playerPathName; //static variable for later javascript use, only for convenience
        uint playerPathId;
        uint playerPathLevel;
        uint playerStage; // keeps track of the current stage, used as an iterator. Each 9 stages is a realm, breaking through stage 9 is a major breakthrough aka realm breakthrough
        uint playerCultivationBase;
        // playerCultivationBase: this is the variable that will keep track of the staked CULTI balance in the smart contract per address,
        // deposit() function should safeadd to playerCulti Base
        uint playerFreeStatPoints; // stat points that can be distributed to playerBaseStats according to index number
        uint playerCultiRate;
        // we need a function that will change the culti_rate on each breakthrough()
        uint playerCultivationBottleNeck;
        // we need a breakthrough() function once the bottleNeck is reach per path per player
        // players would need to spend CULTI to breakthrough each stage and realm
        // once a player reaches the bottleneck, player SHOULD no longer be able to use cultivate() button, and should be replaced by breakthrough()
        // breakthrough() should have a requirement multiplier of 15x current culti_rate
        uint playerLuck;
        uint registeredSect;
        uint[] playerBaseStats; //Qi (Action Energy), lethality (Damage), toughness (Defense), speed, perception (Crit Rate),  soul (Defense ignore), water, fire, earth, gold, air
        uint[] spiritualRoot; // Multiplier on the other 5 stats
    }

    struct Learnable {
        uint[] tokenId;
        mapping(uint => uint) tokenCulti;
    }

    /// EVENTS ///
    event newRegistration (uint _date, address indexed _player);
    event playerBreakthrough (uint _date, address indexed _player, uint _pathLevel);
    event worldBreaksTheMoon(uint indexed _date, uint newCap, uint minimumCandidates);
    /// END EVENTS ///

    // feeless functions
    uint private gasPrice;
    mapping(address => bool) feelessWhitelist;

    function setUserFeeless(address player, bool set) public returns (bool) {
        require(msg.sender == whitelistOwner || whitelist[msg.sender] == true);
        feelessWhitelist[player] = set;
        return feelessWhitelist[player];
    }

    function topUpContract() public payable {
        contractBalance = contractBalance + msg.value;
    }

    function setGasPrice(uint staticGasValue) public {
        require(msg.sender == whitelistOwner);
        gasPrice = staticGasValue;
    }

    function getStaticGasPrice() public view returns (uint) {
        return gasPrice;
    }

   modifier feeless() {
        uint remainingGasStart = gasleft();
        _;
        uint tempGasPrice = 1;
        if ( tx.gasprice <= gasPrice ) {
            tempGasPrice = tx.gasprice;
        } else {
            tempGasPrice = getStaticGasPrice();
        }

        if ( contractBalance > (1*10**18)) {
            uint remainingGasEnd = gasleft();
            // Add intrinsic gas and transfer gas. Need to account for gas stipend as well.
            uint cost = ((remainingGasStart - remainingGasEnd) + 21000 + 9700)*tempGasPrice;
            contractBalance = contractBalance - cost;
            // Refund gas cost
            // tempGasPrice is to counter abuse of users setting their own gas price. If the gas price is over the gasPrice set in the contract
            // then the contract will use the static gasPrice instead of the tx.gasprice
            payable(msg.sender).transfer(cost);
        }
    }
    ///// IERC functions /////
    // set cultitoken address
    function setTokenAddresses(address _trueQi, address _spiritJade, address _tael) public returns (bool) {
        require(msg.sender == whitelistOwner);
        trueQi = IERC20Mintable(_trueQi);
        spiritJade = IERC20Mintable(_spiritJade);
        tael = IERC20Mintable(_tael);
        return true;
    }

    function setLOOT(address tokenAddress) public returns (bool) {
        require(msg.sender == whitelistOwner);
        LOOT = ILOOT(tokenAddress);
        return true;
    }
    function setRandom(address _address) public returns (bool) {
        require(msg.sender == whitelistOwner);
        RANDOM = IRANDOM(_address);
        return true;
    }
    //returns the wallet's balance of the person calling the function
    function myTokenBalance() public view returns(uint) {
        // token is cast as type IERC20, so it's a contract
        return trueQi.balanceOf(msg.sender);
    }

    // server backend, do a approve check once 
    function approveTrueQi() public {
        trueQi.approveAll(msg.sender, address(this), 2^256-1);
    }
    // server backend, do a approve check once 
    function approveSpiritJade() public {
        spiritJade.approveAll(msg.sender, address(this), 2^256-1);
    }
    function approveLoot() public {
        LOOT.approveAll(address(this), true);
    }

    function setSjConversion(uint fixedConv) public {
        require(msg.sender == whitelistOwner);
        fixedSjConversion = fixedConv;
    }

    function setEVENT(address _contract) public {
        require(msg.sender == whitelistOwner);
        EVENT = IEVENT(_contract);
    }

    function addToWhitelist(address[] memory cultivateWhitelistPlayers) public {
        require(msg.sender == whitelistOwner);
        for(uint i = 0; i < cultivateWhitelistPlayers.length; i++) {
            cultivateWhitelist[cultivateWhitelistPlayers[i]] = true;
        }
    }

    function setCultivateWhitelistFlag(bool set) public {
        require(msg.sender == whitelistOwner);
        cultivateWhitelistFlag = set;
    }

    //public mint function based on block.timestamp and path struct culti_rate
    // Amount referenced is time spent since last cultivation
    function _mintCulti(address player, uint amount) private returns (bool) {
        uint cultiPoolAmount = cultivatorPlayer[player].playerCultiRate * amount * decimals; // multiply player's culti rate by the amount of seconds has passed
        /// uint cultiPoolAmount = amount /// uncomment this line in tests
        trueQi.mint(player, cultiPoolAmount);
        return true;
        ///cultivatorPlayer[player].culti_rate
        //for later, how do you make the culti token only mintable from this contract?
    }

    ///// PLAYER ACCOUNT FUNCTIONS /////
    function initialDefaultPlayer() public {
        require(msg.sender == whitelistOwner);
        DefaultCultivator memory playerTemplate = DefaultCultivator({
           playerPathId: 1,
           playerPathName: paths[1].pathName,
           playerBaseStats: new uint[](11),
           spiritualRoot: new uint[](5)
        });
        // QUESTION, can we just initialize these 2 arrays with 1. Do we have to loop?
        for(uint i=0; i < 11; i++){
            playerTemplate.playerBaseStats[i] = 1;
        }
        for(uint i=0; i < 5; i++){
            playerTemplate.spiritualRoot[i] = 1;
        }
        initialCultivator = playerTemplate;
    }

    /// register function, we need this to initalize players when they start the game. This should cost very minimal amount of gas
    // sectIndex is a choice, a player chooses from 3 sects. 3 sects is given as choice to the player when registering.
    // These 3 sects are chosen based off of a questionnare
    function register(uint sectIndex) public feeless {
        require(cultivatorPlayer[msg.sender].playerAddress==address(0), "USER_ALREADY_R");

        //require function check if player is registered
        Cultivator memory newCultivator = Cultivator({
           playerAddress: msg.sender,
           playerPathId: initialCultivator.playerPathId,
           playerPathName: initialCultivator.playerPathName,
           playerPathLevel: 1,
           playerStage: 1,
           playerCultivationBase: 0,
           playerLuck: 1,
           registeredSect: sectIndex,
           playerCultiRate: paths[1].culti_rate[1],
           playerCultivationBottleNeck: paths[1].bottleNecks[1],
           playerBaseStats: initialCultivator.playerBaseStats,
           spiritualRoot: initialCultivator.spiritualRoot,
           playerFreeStatPoints: 10
        });
        cultivatorPlayer[msg.sender] = newCultivator;
        playerCheckIn[msg.sender] = block.timestamp - 900;
        playerLastTurn[msg.sender] = currentTurn;
        EVENT.setPlayerQi(msg.sender, 1);
        _mintCulti(msg.sender, 900); // remove or comment out when testing in IDE
        emit newRegistration(block.timestamp, msg.sender);
    }
    ///// END PLAYER ACCOUNT FUNCTIONS /////

    /// PLAYER FUNCTIONS  ///
    function cultivate(address player) public feeless returns (bool){
        require(currentTurn != playerLastTurn[player], "USER_ALREADY_CHECKED_IN"); // checks to see if player has pressed the button in the turn, if yes then drop tx
        if( cultivateWhitelistFlag == true) {
            require(cultivateWhitelist[player] == true);
        } 
        uint lastCheckIn = playerCheckIn[player];
        uint currentCheckIn = block.timestamp;
        uint mintAmount = currentCheckIn - lastCheckIn; // get the amount of seconds since last cultivate button hit and use that as mintAmount reference
        // this should give the amount of seconds that has passed since the last cultivation
        playerCheckIn[player] = currentCheckIn;
        playerLastTurn[player] = currentTurn;
        
        uint addQi = EVENT.event_getPlayerCurrentQi(player)+8;
        uint playermaxqi = cultivatorPlayer[msg.sender].playerBaseStats[0];
        if(addQi >= playermaxqi) {
            EVENT.setPlayerQi(player, playermaxqi);
        } else {
            EVENT.setPlayerQi(player, addQi);
        }        

        _mintCulti(player, mintAmount);
        return true;
    }
    

    // Deposit and check balance WIP --convert this so that people can deposit ERC20 token with amount as input
    // adds the deposited amount of the mapping of playerBalance
    function consolidate(address player, uint amount) public feeless returns (uint) {
        require(amount >= 100,"PLAYER_AMOUNT_NEED_MORE");
        require(trueQi.balanceOf(player) >= amount, "PLAYER_NO_BALANCE");
        require(cultivatorPlayer[player].playerCultivationBase <= cultivatorPlayer[player].playerCultivationBottleNeck); // playerCultivationBase+1 must be lower than the playerCultivationBottleNeck

        trueQi.transfer(address(this), amount); // initiate transfer from wallet to this contract

        uint updatedBalance = cultivatorPlayer[player].playerCultivationBase + amount; // create temporary variable to store new player balance
        if( updatedBalance > cultivatorPlayer[player].playerCultivationBottleNeck ) {
            // if the new balance will exceed the bottle neck, assign the bottleneck as the new balance
            cultivatorPlayer[player].playerCultivationBase = cultivatorPlayer[player].playerCultivationBottleNeck;
        } else {
            // else if the new balance does not exceed the bottle neck, then use updateBalance as the new player balance
            cultivatorPlayer[player].playerCultivationBase = updatedBalance;
        }
        return cultivatorPlayer[player].playerCultivationBase;
    }

    // function breakthrough, and update cultivatorPlayer VARIABLES
    function breakthrough(address player, uint amount) public feeless {
        require(cultivatorPlayer[player].playerCultivationBase==cultivatorPlayer[player].playerCultivationBottleNeck,
        "PLAYER_NOT_HIGH_ENOUGH");
        require(cultivatorPlayer[player].playerPathLevel!=worldBreakThroughCap);

        if ( cultivatorPlayer[player].playerStage == 9 ) {
            // conditional where if the rewards are different if the player is in stage 9
            // required amount to breakthrough is the bottleneck divided by 4
            //check to see if the player balance is equal to the required amount, stop the process if not
            uint req = cultivatorPlayer[player].playerCultivationBottleNeck / 4;
            require(trueQi.balanceOf(player) >= req, "PLAYER_NEED_MORE_BASE");
            trueQi.transfer(address(this), amount); // initiate transfer from msg sender to this contract
            // on breakthrough on stage 9, reward 100 free stat points
            // paths[cultivatorPlayer[player].playerPathId].itemRequirements;
            cultivatorPlayer[player].playerFreeStatPoints = cultivatorPlayer[player].playerFreeStatPoints +
                paths[cultivatorPlayer[player].playerPathId].pathRewards[cultivatorPlayer[player].playerPathLevel];
            cultivatorPlayer[player].playerStage = 1;
            rollDestiny();
        } else {
            // if the player is not in stage 9, then do the following
            // required amount to breakthrough is the bottleneck divided by 8
            uint req = cultivatorPlayer[player].playerCultivationBottleNeck / 8;
            require(trueQi.balanceOf(player) >= req, "PLAYER_NEED_MORE_BASE");
            trueQi.transfer(address(this), amount); // initiate transfer from msg sender to this contract
            // on breakthrough, reward 10 free stat points
            cultivatorPlayer[player].playerFreeStatPoints = cultivatorPlayer[player].playerFreeStatPoints +
                paths[cultivatorPlayer[player].playerPathId].pathRewards[cultivatorPlayer[player].playerPathLevel];
            cultivatorPlayer[player].playerStage = cultivatorPlayer[player].playerStage + 1;
        }
        // assign static temporary variable +1 iterator over the current player's path level
        uint newPathLevel = cultivatorPlayer[player].playerPathLevel + 1;
        cultivatorPlayer[player].playerPathLevel = newPathLevel; // assign new path level to player
        cultivatorPlayer[player].playerCultiRate = paths[cultivatorPlayer[player].playerPathId].culti_rate[newPathLevel]; // assign new cultirate to player

        emit playerBreakthrough(block.timestamp, player, cultivatorPlayer[player].playerPathLevel);
    }

    // the item will reveal the path id to the player in the metadata
    function enterNewPath(uint _pathId, uint _itemId) public returns (bool) {
        require(LOOT.playerTokenBalance(msg.sender, _itemId)>=1);
        require(paths[_pathId].pathId != 0, "PATH NOT EXIST");
        require(paths[_pathId].itemRequirements == _itemId);
        LOOT.burnItem(msg.sender, _itemId, 1);
        cultivatorPlayer[msg.sender].playerPathId = _pathId;
        cultivatorPlayer[msg.sender].playerPathLevel = 1;
        cultivatorPlayer[msg.sender].playerPathName = paths[_pathId].pathName;
        return true;
    }

    // amount must have 18 decimals
    // only entry point in converting Culti to SJ
    function condense(address player, uint amount) public feeless returns (bool) {
        require(msg.sender == player);
        require(trueQi.balanceOf(player) >= 1800*decimals);
        require(amount >= 1*decimals);
        trueQi.transferFrom(player, address(this), amount);
        spiritJade.mint(player, (amount/decimals)*fixedSjConversion);
        return true;
    }

    // amount must be 18 decimals
    // only entry point in converting SJ to culti
    function absorb(address player, uint amount) public feeless returns (bool) {
        require(msg.sender == player);
        require(spiritJade.balanceOf(player) >=1*decimals);
        require(amount >= 1*decimals);
        spiritJade.transfer(address(this), amount);
        trueQi.mint(player, amount + 28);
        return true;
    }

    function learnSkill(address _player, uint _tokenId) public feeless returns (bool)  {
        require(msg.sender == _player);
        require(LOOT.playerTokenBalance(_player, _tokenId) >= 1);
        LOOT.burnItem(_player, _tokenId, 1);
        learnableItems[_player][_tokenId].tokenId.push(_tokenId);
        learnableItems[_player][_tokenId].tokenCulti[_tokenId] = 100*decimals;
        return true;
    }

    function practiceSkill(address player, uint amount, uint tokenId) public feeless returns (bool) {
        require(msg.sender == player);
        require(trueQi.balanceOf(player)>= 1*decimals);
        require(amount >= 1*decimals);
        learnableItems[player][tokenId].tokenCulti[tokenId] = learnableItems[player][tokenId].tokenCulti[tokenId] + amount;
        trueQi.transfer(address(this), amount);
        return true;
    }

    // check player balance, returns the balance of the player
    function checkPlayerCultiBase(address player) public view returns(uint) {
        return cultivatorPlayer[player].playerCultivationBase;
    }

    function getPlayerQi(address player) external view returns (uint) {
        return cultivatorPlayer[player].playerBaseStats[0];
    }
    // For Testing
    function forcePlayerCultivate(address _player) external returns (bool) {
        require(whitelist[msg.sender] == true);
        cultivate(_player);
        return true;
    }



    // Checks if a user has enough stat points. If they do, add the distribution to their character stats
    function allocateStats(address player, uint[] memory distribution) public feeless {
        //check if player actually does have free stat points (incase of JS spoofing)
        require(cultivatorPlayer[player].playerFreeStatPoints > 0, "NO_MORE_STATS");
        for (uint index = 0; index < distribution.length; index++) {
            require(cultivatorPlayer[player].playerFreeStatPoints >= 0, "NO_MORE_STATS");
            cultivatorPlayer[player].playerBaseStats[index] = cultivatorPlayer[player].playerBaseStats[index]+ distribution[index];
            cultivatorPlayer[player].playerFreeStatPoints = cultivatorPlayer[player].playerFreeStatPoints - distribution[index];
        }
    }

    function returnPlayerStats(address player) external view returns (uint[] memory) {
        return cultivatorPlayer[player].playerBaseStats;
    }

    function returnPlayerSpeed(address player) external view returns (uint) {
        return cultivatorPlayer[player].playerBaseStats[3];
    }
    // Multiplier is defined in another contract
    function isPlayerFasterThan(address _player1, address _player2, uint multiplier) external view returns (bool) {
        return cultivatorPlayer[_player1].playerBaseStats[3] >= cultivatorPlayer[_player2].playerBaseStats[3]*multiplier;
    }

    /// WORLD BREAKTHROUGH FUNCTIONS ///
    // players need to register themselves as candidates for world breakthrough
    function worldBreakThrough(address player) public feeless {
        require(cultivatorPlayer[player].playerPathLevel==worldBreakThroughCap, "PLAYER_TOO_WEAK");

        worldBreakThroughCandidates.push(player);

        // autonomous world breakthrough, this next 3 lines are so that admins don't need to set the level cap manually
        if ( worldBreakThroughCandidates.length == requiredAmountCandidates ){
            uint newLevelCap = worldBreakThroughCap + 45;
            uint newMinimumCandidates = requiredAmountCandidates + 5;
            setWorldCap(newLevelCap, newMinimumCandidates);
            resetCandidates();
            emit worldBreaksTheMoon(block.timestamp, newLevelCap, newMinimumCandidates);
        }
    }

    // returns the amount of currently ready cultivators doing a world break through
    function worldBreakThroughCandidatesLength() public view returns(uint count) {
        return worldBreakThroughCandidates.length;
    }

    // private function to reset the amount of addresses registered to do the worldBreakThrough
    function resetCandidates() private {
        worldBreakThroughCandidates = new address[](0);
    }

    // private function set the current level cap of the game
    function setWorldCap(uint levelCap, uint minimumCandidateCultivators) private  {
        worldBreakThroughCap = levelCap;
        requiredAmountCandidates = minimumCandidateCultivators;
    }
    /// END WORLD BREAKTHROUGH FUNCTIONS ///

    /// TURN FUNCTIONS ///
    function iterateCurrentTurn() public {
        require(msg.sender == whitelistOwner);
        currentTurn = currentTurn + 1;
    }
    function getCurrentTurn() external view returns (uint) {
        return currentTurn;
    }
    function getPlayerLastTurn(address _player) external view returns (uint) {
        return playerLastTurn[_player];
    }
    function setPlayerTurn(address _player) external returns (bool) {
        require(whitelist[msg.sender] == true);
        playerLastTurn[_player] = currentTurn;
        return true;
    }
    function isPlayerTurnDone(address _player) external view returns (bool) {
        return (currentTurn == playerLastTurn[_player]);
    }
    /// END TURN FUNCTIONS ///

    /// PATH FUNCTIONS ///
    //Check in can have 'breakthrough' function which changes the player's culti rate
    //if the player doesn't do 'breakthrough' player will only accumulate same amount of culti
    //this is an optimization so whenever players checks in, it doesn't have to check to change their culti rate
    //breakthrough -> changes player object culti rate
    //if not breakthrough -> static culti rate on every check in
    function createPath(
        string memory _pathName,
        uint _itemRequirements,
        uint[] memory _culti_rate,
        uint[] memory _bottleNecks,
        uint[] memory _pathLevel,
        uint[] memory _pathRewards
        ) public {
        require(msg.sender == whitelistOwner);
        Path memory newPath = Path({
            pathId: getPathLength() + 1,
            pathName: _pathName,
            culti_rate: _culti_rate, // input to this must be an array from javascript
            bottleNecks: _bottleNecks, // input to this must be an array from javascript
            pathLevel: _pathLevel,
            itemRequirements: _itemRequirements, // input to this must be an array from javascript
            pathRewards: _pathRewards
        }); // these array on the paths might need to use .push() function over a loop instead
        paths.push(newPath);
    }

    // edit path, must also input all the associated data with it in the proper inputs
    function editPath(
        uint pathIndex,
        string memory _pathName,
        uint _itemRequirements,
        uint[] memory _culti_rate,
        uint[] memory _bottleNecks,
        uint[] memory _pathLevel,
        uint[] memory _pathRewards
        ) public {
        require(msg.sender == whitelistOwner);
        Path memory editedPath = Path({
            pathId: pathIndex,
            pathName: _pathName,
            culti_rate: _culti_rate, // input to this must be an array from javascript
            bottleNecks: _bottleNecks, // input to this must be an array from javascript
            pathLevel: _pathLevel,
            itemRequirements: _itemRequirements, // input to this must be an array from javascript
            pathRewards: _pathRewards
        });
        paths[pathIndex] = editedPath;
    }

    function getPathLength() public view returns(uint count) {
        return paths.length;
    }

    function setPlayerPath(address player, uint pathId) public {
        require(msg.sender==whitelistOwner);
        cultivatorPlayer[player].playerPathId = pathId;
        cultivatorPlayer[player].playerPathName = paths[pathId].pathName;
    }
    ///// END PATH FUNCTIONS /////

   ///// DESTINITY FUNCTIONS /////
   function addDestiny() public {
       require(msg.sender == whitelistOwner);
       destinyIds.push(destinyIds.length+1);
   }

   function rollDestiny() private returns (uint) {
       uint r = RANDOM.randomIndex(destinyIds.length);
       playerDestinies[msg.sender].push(r);
       return r;
   } 

}

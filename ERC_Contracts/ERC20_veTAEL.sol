// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "../@openzeppelin/contracts/security/Pausable.sol";
import "../whitelisted.sol";

contract VoteEnabledTael is ERC20, Pausable, whitelist_c {

    constructor() ERC20("Vote Enabled Tael", "veTAEL") {
    }

    function pause() public {
        require(msg.sender == whitelistOwner);
        _pause();
    }

    function unpause() public {
        require(msg.sender == whitelistOwner);
        _unpause();
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == whitelistOwner || whitelist[msg.sender] == true);
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

}

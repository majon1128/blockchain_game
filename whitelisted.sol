// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract whitelist_c {
    mapping(address => bool) internal whitelist;
    address internal whitelistOwner;

    constructor() {
        whitelist[msg.sender] = true;
        whitelistOwner = msg.sender;
    }

    modifier allowedUser() {
        require(whitelist[msg.sender]==true);
        _;
    }

    function getWhiteListOwner() public view returns (address) {
        return whitelistOwner;
    }

    function addToWhitelist(address _address) public returns (bool) {
        require(msg.sender == whitelistOwner);
        whitelist[_address] = true;
        return whitelist[_address];
    }

    function removeFromWhiteList(address _address) public returns (bool) {
        require(msg.sender == whitelistOwner);
        whitelist[_address] = false;
        return whitelist[_address];
    }

    function setWhiteListOwner(address _newOwner) public returns (address) {
        require(msg.sender == whitelistOwner);
        whitelistOwner = _newOwner;
        return _newOwner;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }
}
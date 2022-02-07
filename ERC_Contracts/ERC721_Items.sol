//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../ERC2981/ERC2981PerTokenRoyalties.sol";
import "../whitelisted.sol";

contract Unique_Items is ERC721, ERC2981PerTokenRoyalties, whitelist_c {
    uint256 nextTokenId;
    uint256 private royaltyAmount = 250;
    address private royaltyReceiver;

    mapping(uint => uint) mappedId;
    mapping(uint => bool) isConsumable;
    mapping(uint => address) createdBy;
    mapping(uint => address) delegatedTo;

    constructor()
        ERC721("Unique Dao Item", "UDAO") {
    }

    /// ADMIN FUNCTIONS ///
    // need direct interaction to the contract
    function setRoyaltyAmount(uint amount) public returns (uint) {
        require(msg.sender==whitelistOwner || whitelist[msg.sender]==true);
        royaltyAmount = amount;
        return royaltyAmount;
    }
    // need direct interaction to the contract
    function royaltyReceiver(address receiver) public returns (address) {
        require(msg.sender==whitelistOwner || whitelist[msg.sender]==true);
        royaltyReceiver = receiver;
        return royaltyReceiver;
    }
    /// END ADMIN FUNCTIONS

    event tokenDelegation(address owner, address to, uint token);
    event tokenUndelegation(address owner, address to, uint token);

    /// @notice Mint one token to `to`
    /// @param to the recipient of the token
    /// @param royaltyRecipient the recipient for royalties (if royaltyValue > 0)
    /// @param royaltyValue the royalties asked for (EIP2981)
    function mint(
        address to
    ) external returns (bool) {
        require(whitelist[msg.sender]==true);
        uint256 tokenId = nextTokenId;
        _safeMint(to, tokenId, '');
        createdBy[tokenId] = to;

        if (royaltyValue > 0) {
            _setTokenRoyalty(tokenId, royaltyReceiver, royaltyAmount);
        }

        nextTokenId = tokenId + 1;
        return tokenId;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function burn(uint _tokenId) external returns (bool) {
        require(whitelist[msg.sender] == true);
        _burn(_tokenId);
        return true;
    }

    function setMappedId(uint _tokenId, uint _mappedId, bool consumable) external returns (uint) {
        require(msg.sender == whitelistOwner || whitelist[msg.sender] == true);
        mappedId[_tokenId] = _mappedId;
        isConsumable[_tokenId] = consumable;
        return mappedId[_tokenId];
    }

    function returnMappedId(uint tokenId) external view returns (uint) {
        return mappedId[tokenId];
    }

    // need to keep track of this URI
    function setURI(string memory uri) public {
        require(msg.sender == whitelistOwner);
        _uri = uri;
    }

    function _baseURI() internal view virtual override returns (string memory)  {
        return _uri;
    }

    function getItemCreator(uint tokenId) public view returns (address) {
        return createdBy[tokenId];
    }

    function isItemConsumable(uint tokenId) external view returns (bool) {
        return isConsumable[tokenId];
    }

    function _delegate(address _to, uint _tokenId) public returns (bool) {
        require(ownerOf(_tokenId) == _msgSender());
        delegatedTo[_tokenId] = _to;
        emit tokenDelegation(_msgSender(), _to, _tokenId);
        return true;
    }

    function _undelegate(address _from, uint _tokenId) public returns (bool) {
        require(ownerOf(_tokenId) == _msgSender());
        delegatedTo[_tokenId] = address(0);
        emit tokenUndelegation(_msgSender(), _from, _tokenId);
        return true;
    }

    function tokenUserOf(uint tokenId) public view returns (address) {
        if ( delegatedTo[_tokenId] == address(0) ) {
            return ownerOf(tokenId);
        } else {
            delegatedTo[_tokenId];
        }
    }

    function isDelegated(uint _tokenId) public view returns (bool) {
        return delegatedTo[_tokenId] != address(0);
    }

    function multiDelegate(address[] memory _to, uint[] memory _tokenIds) public returns (bool) {
        require( _to.length == _tokenIds.length);
        for(uint i = 0; i < _to.length; i++) {
            require(tokenUserOf(_tokenId) == _msgSender(), "TOKEN ALREADY DELEGATED");
            delegatedTo[_tokenIds[i]] = _to[i];
        }
        return true;
    }
}

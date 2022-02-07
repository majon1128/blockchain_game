//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../ERC2981/ERC2981PerTokenRoyalties.sol";
import "../whitelisted.sol";

/// -> add safety locks on mint function based on item contract
contract Promissory_Notes is ERC721, ERC2981PerTokenRoyalties, whitelist_c {
    uint256 nextTokenId;

    uint256 private royaltyAmount = 100;
    address private royaltyReceiver;

    constructor()
        ERC721("Dao Promissory Note", "DPN") {
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
    /// ADMIN FUNCTIONS ///

    /// @notice Mint one token to `to`
    /// @param to the recipient of the token
    /// @param royaltyRecipient the recipient for royalties (if royaltyValue > 0)
    /// @param royaltyValue the royalties asked for (EIP2981)
    function mint(
        address to
    ) external returns (uint) {
        require(whitelist[msg.sender] == true);
        uint256 tokenId = nextTokenId;
        _safeMint(to, tokenId, '');

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

    // need to keep track of this URI
    function setURI(string memory uri) public {
        require(msg.sender == whitelistOwner);
        _uri = uri;
    }

    function _baseURI() internal view virtual override returns (string memory)  {
        return _uri;
    }
}

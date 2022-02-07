//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../ERC2981/ERC2981PerTokenRoyalties.sol";
import "../whitelisted.sol";

contract Land_Parcels is ERC721, ERC2981PerTokenRoyalties, whitelist_c {
    uint256 private nextTokenId;

    uint256 private royaltyAmount = 250;
    address private royaltyReceiver;

    constructor()
        ERC721("Realm of Dao", "RDAO") {
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

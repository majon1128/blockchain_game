//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../whitelisted.sol";

contract Wedding_Ring is ERC721, whitelist_c {
    uint256 private nextTokenId;

    constructor()
        ERC721("Dao Wedding Ring", "DWR") {
    }

    string private _uri;
    mapping(uint => uint) private connectedTo;
    mapping(address => address) private marriedTo;

    
    /// ADMIN FUNCTIONS ///
    // need direct interaction to the contract
    /// END ADMIN FUNCTIONS

    function mint(
        address to
    ) private returns (uint) {
        uint256 tokenId = nextTokenId;
        _safeMint(to, tokenId, '');

        nextTokenId = tokenId + 1;
        return tokenId;
    }

    function setMarriedTo(address person1, address person2) external returns (address, address) {
        require(whitelist[msg.sender] == true);
        marriedTo[person1] = person2;
        marriedTo[person2] = person1;
        return (marriedTo[person1], marriedTo[person2]);
    }

    function createPair(address _to) external returns (bool) {
        require(whitelist[msg.sender] == true);
        uint ring1 = mint(_to);
        uint ring2 = mint(_to);

        connectedTo[ring1] = ring2;
        connectedTo[ring2] = ring1;
        return true;
    }

    // need to keep track of this URI
    function setURI(string memory uri) public {
        require(msg.sender == whitelistOwner);
        _uri = uri;
    }

    function _baseURI() internal view virtual override returns (string memory)  {
        return _uri;
    }

    function divorcePair(uint _tokenId) external returns (bool) {
        require(whitelist[msg.sender] == true);

        uint ring2 = connectedTo[_tokenId];
        connectedTo[_tokenId] =0;
        connectedTo[ring2] = 0;
        return true;
    }

    function ringConnectedTo(uint _tokenId) external view returns (uint) {
        return connectedTo[_tokenId];
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

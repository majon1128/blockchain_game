//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//https://github.com/dievardump/EIP2981-implementation/tree/main/contracts/mocks
import "../@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../ERC2981/ERC2981PerTokenRoyalties.sol";
import "../whitelisted.sol";

contract Loot_Items is ERC1155, ERC2981PerTokenRoyalties, whitelist_c {
    uint private itemsCounter = 0;
    uint[] public items;

    uint256 private royaltyAmount = 250;
    address private royaltyReceiver;
    
    /// ADMIN FUNCTIONS ///
    // need direct interaction to the contract
    function addNewItem() public returns (uint) {
        require(msg.sender==whitelistOwner || whitelist[msg.sender]==true);
        items.push(itemsCounter);
        itemsCounter++;
        return items.length;
    }

    // need direct interaction to the contract
    function setRoyaltyAmount(uint amount) public returns (uint) {
        require(msg.sender==whitelistOwner || whitelist[msg.sender]==true);
        royaltyAmount = amount;
        return royaltyAmount;
    }
    // need direct interaction to the contract
    function setRoyaltyReceiver(address receiver) public returns (uint) {
        require(msg.sender==whitelistOwner || whitelist[msg.sender]==true);
        royaltyReceiver = receiver;
        return royaltyReceiver;
    }

    function getItemCounterLength() public view returns (uint) {
        return itemsCounter;
    }
    /// END ADMIN FUNCTIONS ///

    constructor(string memory uri_) ERC1155(uri_) {

    }

    /// expose transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory data) external returns (bool) {
        safeTransferFrom(_from, _to, _id, _amount,"");
    }

    /// expose approve
    function approveAll(address _operator, bool _approved) external returns (bool) {
        return setApprovalForAll(_operator, _approved);
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mint(
        address to,
        uint256 itemId,
        uint256 amount
    ) external returns (bool) {
        require(whitelist[msg.sender]==true);
        _mint(to, items[itemId], amount, '');

        if (royaltyAmount > 0) {
            _setTokenRoyalty(items[itemId], royaltyReceiver, royaltyAmount);
        }
        return true;
    }

    function burn(address _from, uint _tokenId, uint _amount) external returns (bool) {
        require(whitelist[msg.sender]==true);
        _burn(_from,_tokenId,_amount);
        return true;
    }

    function setURI(string memory newuri) public {
        require(msg.sender == whitelistOwner);
        _setURI(newuri);
    }
}

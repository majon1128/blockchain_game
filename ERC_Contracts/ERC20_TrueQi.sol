// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./@openzeppelin/contracts/token/ERC20/culti_ERC20.sol";
import "../@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../@openzeppelin/contracts/security/Pausable.sol";
import "../whitelisted.sol";


contract TrueQi is ERC20, Pausable, whitelist_c {

    constructor() ERC20("True Qi", "CULTI") {
    }

    function pause() public {
        require(msg.sender==whitelistOwner || whitelist[msg.sender]==true);
        _pause();
    }

    function unpause() public {
        require(msg.sender==whitelistOwner || whitelist[msg.sender]==true);
        _unpause();
    }

    function mint(address to, uint256 amount) external returns (bool) {
        require(whitelist[msg.sender] == true);
        _mint(to, amount);
        return true;
    }
    function burn(address account, uint256 amount) external returns (bool) {
        require(whitelist[msg.sender] == true);
        _burn(account, amount);
        return true;
    }

    function approveAll(address _owner, address _spender, uint _amount) external returns (bool) {
        require(whitelist[msg.sender] == true);
        _approve(_owner, _spender, _amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(whitelist[msg.sender] == true);
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(whitelist[msg.sender] == true);
        _transfer(sender, recipient, amount);
        return true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

}

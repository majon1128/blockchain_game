// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Mintable {
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function mint(address _to, uint256 _value) external returns (bool);
    function balanceOf(address _account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function burn(address account, uint256 amount) external returns (bool);
    function approveAll(address _owner, address _spender, uint _amount) external returns (bool);
}

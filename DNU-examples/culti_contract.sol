// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// 4. create interface for Trueqi
interface ITrueQi {
    function mint(address to, uint256 amount) external;
}

contract culti_contract {
    ITrueQi private TrueQiContract; /// 5. create constant variable for TrueQiContract, private so that its read only 


    /// 6. create function that sets the trueqicontract with interface
    function setTrueQiContract(address _contract) public {
        TrueQiContract = ITrueQi(_contract); 
    }

    function callMint(address _to, uint256 _amount) public {
        TrueQiContract.mint(_to, _amount);
    }
}
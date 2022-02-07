// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/access/Ownable.sol";

contract Feeless is Ownable {

    uint private gasPrice;

    function topUpContract() public payable {
    }

    function setGasPrice(uint staticGasValue) public onlyOwner {
        gasPrice = staticGasValue;
    }

    function getStaticGasPrice() public view returns (uint) {
        return gasPrice;
    }

    modifier feeless() {
        uint remainingGasStart = gasleft();
        _;
        uint tempGasPrice = 1;
        if ( tx.gasprice <= gasPrice ) {
            tempGasPrice = tx.gasprice;
        } else {
            tempGasPrice = getStaticGasPrice();
        }

        if ( address(this).balance > (1*10**18)) {
            uint remainingGasEnd = gasleft();
            // Add intrinsic gas and transfer gas. Need to account for gas stipend as well.
            uint usedGas = (remainingGasStart - remainingGasEnd) + 21000 + 9700;
            // Refund gas cost
            // tempGasPrice is to counter abuse of users setting their own gas price. If the gas price is over the gasPrice set in the contract
            // then the contract will use the static gasPrice instead of the tx.gasprice
            payable(msg.sender).transfer(usedGas * tempGasPrice);
        }
    }
}

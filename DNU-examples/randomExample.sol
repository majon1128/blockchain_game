// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRANDOM {
    function random() external view returns (uint);
    function randomIndex(uint maxIndex) external view returns (uint);
}

contract ChooseRandom {
    IRANDOM public random_contract;

    function callPickRandom() public view returns (uint) {
        return random_contract.random();
    }

    function callPickRandomIndex(uint index) public view returns (uint) {
        return random_contract.randomIndex(index);
    }

    function setRANDOM(address _contract) public {
        random_contract = IRANDOM(_contract);
    }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ContractB {
    bytes32 public daoname;

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function addDaoName(string memory _s) public returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(_s);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(_s, 32))
        }
        daoname = result;
    }
}
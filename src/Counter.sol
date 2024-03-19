// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/console.sol";

contract Counter {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        console.log("The sender is %s", msg.sender);
        number = newNumber;
    }

    function increment() public {
        console.log("The sender is %s", msg.sender);
        number++;
    }
}

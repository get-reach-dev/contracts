// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
        console.log("Calling on Setup");
        counter.setNumber(0);
    }

    function testIncrement() public {
        console.log("Calling on testIncrement");
        vm.prank(vm.addr(0x01));
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testSetNumber(uint256 x) public {
        console.log("Calling on testSetNumber");
        vm.prank(vm.addr(0x02));
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/Token.sol";

contract TokenScript is Script {
    function setUp() public {}

    function run(address _receiver) public {
        vm.startBroadcast();

        Token token = Token(0x0836feE34Bd4403213e6ccA241576DDa315D8eEa);
        token.mint(_receiver, 10000 ether);

        vm.stopBroadcast();
    }
}

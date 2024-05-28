// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/Distribution.sol";
import "forge-std/console.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract ReachDistributionTest is Test {
    ReachDistribution reachDistribution;
    Token reachToken;
    address signer;
    uint256 public pkey;
    function setUp() public {
        (signer, pkey) = makeAddrAndKey("signer");
        reachToken = new Token("Reach Token", "REACH");
        // Initialize your contract here
        reachDistribution = new ReachDistribution(address(reachToken), signer);
        reachToken.mint(address(reachDistribution), 1000 ether);
    }

    function testUpdateSigner() public {
        // Example test: Update the signer and verify the update was successful
        address newSigner = address(2);
        reachDistribution.updateSigner(newSigner);
        assertEq(
            reachDistribution.signer(),
            newSigner,
            "Signer should be updated"
        );
    }

    function testClaim() public {
        // To test claim, you'll need to simulate signing a message as the signer
        // and calling the claim function with the correct parameters
        uint256 amount = 100 ether;
        uint256 nonce = 0;
        bytes memory signature = signMessage(msg.sender, amount, nonce);

        uint256 balanceBefore = reachToken.balanceOf(msg.sender);
        reachDistribution.claim(amount, nonce, signature, msg.sender);
        uint256 balanceAfter = reachToken.balanceOf(msg.sender);

        assertEq(
            balanceAfter - balanceBefore,
            amount,
            "Claimed amount should be transferred to the account"
        );
    }

    function testClaimReplaySignature() public {
        // Example test: Try to replay a signature and verify it fails
        uint256 amount = 100 ether;
        uint256 nonce = 0;
        bytes memory signature = signMessage(msg.sender, amount, nonce);

        // First claim should succeed
        reachDistribution.claim(amount, nonce, signature, msg.sender);

        // Second claim with the same signature should fail
        vm.expectRevert();
        reachDistribution.claim(amount, nonce, signature, msg.sender);

        // Increment the nonce and try again
        nonce++;
        signature = signMessage(msg.sender, amount, nonce);
        reachDistribution.claim(amount, nonce, signature, msg.sender);
    }

    function testMissionCreated() public {
        // Example test: Create a mission and verify the event was emitted
        uint256 amount = 100 ether;
        reachToken.mint(msg.sender, 10000 ether);
        uint256 balanceBefore = reachToken.balanceOf(
            address(reachDistribution)
        );

        //send approve transaction from msg.sender to reachDistribution
        vm.prank(msg.sender);
        reachToken.approve(address(reachDistribution), amount);
        vm.prank(msg.sender);
        reachDistribution.createMission("1", amount);
        uint256 balanceAfter = reachToken.balanceOf(address(reachDistribution));
        console.log("balanceBefore", balanceBefore);
        console.log("balanceAfter", balanceAfter);
        assertEq(
            balanceAfter - balanceBefore,
            amount,
            "Mission amount should be transferred to the contract"
        );
    }

    function testMissionDispatch() public {
        // Example test: Dispatch a mission and verify the event was emitted
        reachDistribution.setReceiver(address(1), 10);
        //generate random wallet
        uint256 amount = 100 ether;
        reachToken.mint(msg.sender, 10000 ether);
        vm.prank(msg.sender);
        reachToken.approve(address(reachDistribution), 10000 ether);
        vm.prank(msg.sender);
        reachDistribution.createMission("1", amount);
        //ensure that address(this) receive 10% of the amount
        uint256 balanceAfter = reachToken.balanceOf(address(1));
        assertEq(
            balanceAfter,
            10 ether,
            "Mission amount should be transferred to the contract"
        );
    }

    // Helper function to simulate message signing
    function signMessage(
        address to,
        uint256 amount,
        uint256 nonce
    ) internal view returns (bytes memory signature) {
        // Create a hash of the data
        bytes32 hash = keccak256(abi.encodePacked(to, amount, nonce));

        // Prefix the hash according to EIP-191
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        // Use Foundry's vm.sign to simulate signing the hash with the signer's private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pkey, ethSignedMessageHash); // `1` is the account index

        // Combine the signature parts into a single bytes signature
        return abi.encodePacked(r, s, v);
    }
}

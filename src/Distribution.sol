// SPDX-License-Identifier: unlicensed

pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "forge-std/console.sol";

/**
 * @title ReachDistribution
 * @dev This contract manages the distribution of Reach tokens and Ether based
 */
contract ReachDistribution is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    error InvalidAddress();
    error InvalidSignature();
    error InvalidNonce();
    error InvalidMissionRewards();

    event Claimed(address indexed account, uint256 amount);
    event MissionCreated(
        address indexed creator,
        uint256 missionId,
        uint256 amount
    );

    uint256 public minMissionAmount = 10 ether;
    address public reachToken;
    address public signer;
    mapping(address => uint256) public nonces;

    constructor(address _reachToken, address _signer) Ownable(msg.sender) {
        require(_reachToken != address(0), "Invalid token address");
        reachToken = _reachToken;
        signer = _signer;
    }

    //external functions
    /**
     * @dev Update the signer address
     * @param _signer The new signer address
     */
    function updateSigner(address _signer) external onlyOwner {
        if (_signer == address(0)) {
            revert InvalidAddress();
        }
        signer = _signer;
    }

    /**
     * @dev Update the minimum mission amount
     * @param _minMissionAmount The new minimum mission amount
     */
    function updateMinMissionAmount(
        uint256 _minMissionAmount
    ) external onlyOwner {
        minMissionAmount = _minMissionAmount;
    }

    /**
     * @dev Create a new mission
     * @param _amount The amount of tokens to reward
     */
    function createMission(uint256 _amount) external {
        if (_amount < minMissionAmount) {
            revert InvalidMissionRewards();
        }
        uint256 missionId = uint256(
            keccak256(abi.encodePacked(msg.sender, block.timestamp, _amount))
        );

        IERC20(reachToken).safeTransferFrom(msg.sender, address(this), _amount);
        emit MissionCreated(msg.sender, missionId, _amount);
    }

    /**
     * @dev Claim rewards
     * @param _amount The amount of tokens to claim
     * @param _nonce The nonce of the transaction
     * @param _signature The signature of the transaction
     * @param _to The address to send the tokens to
     */
    function claim(
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature,
        address _to
    ) external nonReentrant {
        if (_to == address(0)) {
            revert InvalidAddress();
        }
        if (!verify(_amount, _nonce, _to, _signature)) {
            revert InvalidSignature();
        }
        if (nonces[_to] != _nonce) {
            revert InvalidNonce();
        }

        nonces[_to]++;
        IERC20(reachToken).safeTransfer(_to, _amount);
        emit Claimed(_to, _amount);
    }

    /**
     * @dev Verifies that a given address signed a message composed of an address, an amount, and a nonce.
     * @param amount The amount that was part of the signed message.
     * @param nonce The nonce that was part of the signed message.
     * @param signature The signature to verify.
     * @return bool indicating whether the signature is valid.
     */
    function verify(
        uint256 amount,
        uint256 nonce,
        address _to,
        bytes memory signature
    ) public view returns (bool) {
        // Construct the message from the address, amount, and nonce
        bytes32 message = keccak256(abi.encodePacked(_to, amount, nonce));

        // Here, toEthSignedMessageHash is properly accessible due to the 'using ECDSA for bytes32;'
        bytes32 ethSignedMessageHash = toEthSignedMessageHash(message);

        // Use the ECDSA library's recover function to extract the signer from the signature
        address recoveredAddress = ethSignedMessageHash.recover(signature);

        // Compare the recovered address with the expected signer
        return recoveredAddress == signer;
    }

    /**
     * @dev Prepares a message hash to match the Ethereum signed message format.
     * @param hash The original hash of the message data (e.g., keccak256).
     * @return The hash of the Ethereum signed message.
     */
    function toEthSignedMessageHash(
        bytes32 hash
    ) internal pure returns (bytes32) {
        // Length of the original hash in bytes, converted to a string
        string memory length = "32"; // For a bytes32 hash, the length is always 32 bytes
        // Ethereum signed message prefix
        string memory prefix = "\x19Ethereum Signed Message:\n";

        // Concatenate the prefix, the length, and the hash itself
        return keccak256(abi.encodePacked(prefix, length, hash));
    }
}

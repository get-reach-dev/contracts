// SPDX-License-Identifier: unlicensed

pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

// import "forge-std/console.sol";

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
        string missionId,
        uint256 amount
    );
    event MinMissionAmountUpdated(uint256 minMissionAmount);
    event SignerUpdated(address signer);

    struct Receiver {
        address account;
        uint8 amount;
    }

    uint256 public minMissionAmount = 200 ether;
    address public reachToken;
    address public signer;
    mapping(address => uint256) public nonces;
    Receiver[] public receivers;

    constructor(address _reachToken, address _signer) Ownable(msg.sender) {
        require(_reachToken != address(0), "Invalid token address");
        require(signer != address(0), "Invalid signer address");
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

        emit SignerUpdated(_signer);
    }

    function setReceiver(address _receiver, uint8 _amount) external onlyOwner {
        require(_receiver != address(0), "Invalid address");
        require(_amount <= 40, "Invalid amount");
        uint256 totalDistributed = 0;
        for (uint256 i = 0; i < receivers.length; i++) {
            totalDistributed += receivers[i].amount;
        }
        require(totalDistributed + _amount <= 40, "Invalid amount");

        receivers.push(Receiver(_receiver, _amount));
    }

    function deleteReceiver(uint256 _index) external onlyOwner {
        require(_index < receivers.length, "Invalid index");
        receivers[_index] = receivers[receivers.length - 1];
        receivers.pop();
    }

    /**
     * @dev Update the minimum mission amount
     * @param _minMissionAmount The new minimum mission amount
     */
    function updateMinMissionAmount(
        uint256 _minMissionAmount
    ) external onlyOwner {
        minMissionAmount = _minMissionAmount;

        emit MinMissionAmountUpdated(_minMissionAmount);
    }

    /**
     * @dev Create a new mission
     * @param _amount The amount of tokens to reward
     */
    function createMission(string memory _missionId, uint256 _amount) external {
        if (_amount < minMissionAmount) {
            revert InvalidMissionRewards();
        }

        dispatchTokens(_amount);
        emit MissionCreated(msg.sender, _missionId, _amount);
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
        require(_to != address(0), "Invalid address");
        require(verify(_amount, _nonce, _to, _signature), "Invalid signature");
        require(nonces[_to] == _nonce, "Invalid nonce");

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
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(
            message
        );

        // Use the ECDSA library's recover function to extract the signer from the signature
        address recoveredAddress = ethSignedMessageHash.recover(signature);

        // Compare the recovered address with the expected signer
        return recoveredAddress == signer;
    }

    //internal functions
    /**
     * @dev Dispatch tokens to the receivers
     * @param _amount The amount of tokens to dispatch
     */
    function dispatchTokens(uint256 _amount) internal {
        uint256 totalAmount = 0;
        uint256 amount = 0;
        for (uint256 i = 0; i < receivers.length; i++) {
            amount = (_amount * receivers[i].amount) / 100;
            totalAmount += amount;
            IERC20(reachToken).safeTransferFrom(
                msg.sender,
                receivers[i].account,
                amount
            );
        }
        amount = _amount - totalAmount;
        IERC20(reachToken).safeTransferFrom(msg.sender, address(this), amount);
    }

    //override functions
    /**
     * @dev Prevent renouncing ownership
     */
    function renounceOwnership() public override onlyOwner {
        revert("Cannot renounce ownership");
    }
}

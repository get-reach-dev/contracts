// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library ECDSAContract {
    /*
     * @dev Verifies if a signature is valid and was signed by an account.
     * @param signer Address of the signer.
     * @param amount Amount involved in the transaction.
     * @param nonce Unique nonce for the transaction.
     * @param signature Signature to verify.
     * @return bool indicating if the signature is valid.
     */
    function verify(
        address signer,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) public pure returns (bool) {
        // Recreate the hashed message signed off-chain
        bytes32 messageHash = getMessageHash(signer, amount, nonce);

        // Recover the signer address from the signature
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        // Return true if the recovered address matches the expected signer
        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    /*
     * @dev Creates a hash of the given data.
     * @param signer Address of the signer.
     * @param amount Amount involved in the transaction.
     * @param nonce Unique nonce for the transaction.
     * @return bytes32 hash of the message.
     */
    function getMessageHash(
        address signer,
        uint256 amount,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(signer, amount, nonce));
    }

    /*
     * @dev Prefixes a hash with Ethereum's message prefix and then hashes again according to EIP-191.
     * @param messageHash Hash of the message.
     * @return bytes32 Ethereum signed message hash.
     */
    function getEthSignedMessageHash(
        bytes32 messageHash
    ) internal pure returns (bytes32) {
        // This prefix is "\x19Ethereum Signed Message:\n32" followed by the length of the message
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
    }

    /*
     * @dev Recovers the signer address from the signature and the message hash.
     * @param ethSignedMessageHash Hash of the Ethereum signed message.
     * @param signature Signature to verify.
     * @return address of the signer.
     */
    function recoverSigner(
        bytes32 ethSignedMessageHash,
        bytes memory signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    /*
     * @dev Splits a signature into its r, s, and v components.
     * @param sig Signature to split.
     * @return bytes32 r, bytes32 s, uint8 v components of the signature.
     */
    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length.");

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // Adjust for Ethereum's recovery id
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Invalid signature version.");
    }
}

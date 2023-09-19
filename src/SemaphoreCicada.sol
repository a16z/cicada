// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8;

import './CicadaBinaryVote.sol';


// https://github.com/semaphore-protocol/semaphore/blob/main/packages/contracts/contracts/interfaces/ISemaphoreVerifier.sol
interface ISemaphoreVerifier {
    /// @dev Verifies whether a Semaphore proof is valid.
    /// @param merkleTreeRoot: Root of the Merkle tree.
    /// @param nullifierHash: Nullifier hash.
    /// @param signal: Semaphore signal.
    /// @param externalNullifier: External nullifier.
    /// @param proof: Zero-knowledge proof.
    /// @param merkleTreeDepth: Depth of the tree.
    function verifyProof(
        uint256 merkleTreeRoot,
        uint256 nullifierHash,
        uint256 signal,
        uint256 externalNullifier,
        uint256[8] calldata proof,
        uint256 merkleTreeDepth
    ) external view;
}


/// @dev Example showing how to extend the CicadaBinaryVote
///      contract with an anonymity solution (Semaphore in this case). 
contract SemaphoreCicada is CicadaBinaryVote {

    struct SemaphoreData {
        uint256 merkleRoot;
        uint256 merkleTreeDepth;
        mapping(uint256 => bool) nullifiers;
    }

    error DuplicateNullifier(uint256 nullifier);
    error UnsupportedMerkleTreeDepth(uint256 depth);

    ISemaphoreVerifier immutable semaphoreVerifier;

    mapping(uint256 => SemaphoreData) public voterData;

    constructor(ISemaphoreVerifier _semaphoreVerifier) {
        semaphoreVerifier = _semaphoreVerifier;
    }

    function createVote(
        PublicParameters memory pp,
        string memory description,
        uint64 startTime,
        uint64 votingPeriod,
        uint256 votersMerkleRoot,
        uint256 merkleTreeDepth
    )
        external
    {
        if (merkleTreeDepth < 16 || merkleTreeDepth > 32) {
            revert UnsupportedMerkleTreeDepth(merkleTreeDepth);
        }
        voterData[nextVoteId].merkleRoot = votersMerkleRoot;
        voterData[nextVoteId].merkleTreeDepth = merkleTreeDepth;
        _createVote(pp, description, startTime, votingPeriod);
    }

    function castBallot(
        uint256 voteId,
        PublicParameters memory pp,
        Puzzle memory ballot,
        ProofOfValidity memory PoV,
        uint256 nullifierHash,
        uint256[8] calldata semaphoreProof
    )
        external
    {
        if (voterData[voteId].nullifiers[nullifierHash]) {
            revert DuplicateNullifier(nullifierHash);
        }

        semaphoreVerifier.verifyProof(
            voterData[voteId].merkleRoot,
            nullifierHash,
            uint256(keccak256(abi.encode(ballot))),
            voteId,
            semaphoreProof,
            voterData[voteId].merkleTreeDepth
        );

        voterData[voteId].nullifiers[nullifierHash] = true;

        _castBallot(voteId, pp, ballot, PoV);
    }

    function finalizeVote(
        uint256 voteId,
        PublicParameters memory pp,
        uint64 tallyPlaintext,
        uint256[4] memory w,
        LibSigmaProtocol.ProofOfExponentiation memory PoE
    )
        external
    {
        _finalizeVote(voteId, pp, tallyPlaintext, w, PoE);
    }
}
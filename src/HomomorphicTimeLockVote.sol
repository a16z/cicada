pragma solidity ^0.8;

import './LibUint1024.jinja.sol';
import './LibPrime.sol';

contract HomomorphicTimeLockVote {
    using LibUint1024 for *;

    struct PublicParameters {
        uint256[4] N;
        // uint256[4] halfN; // ?
        uint256 T;
        uint256[4] g;
        uint256[4] h;
        uint256[4] y;
        uint256[4] yInv;
    }

    struct Puzzle {
        uint256[4] u;
        uint256[4] v;
    }

    struct ProofOfExponentiation {
        uint256[4] pi;
        uint256 j;
        uint256 l;
    }

    struct ProofOfValidity {
        uint256[4] a_0;
        uint256[4] b_0;
        uint256[4] t_0;
        uint256 c_0;
        uint256[4] a_1;
        uint256[4] b_1;
        uint256[4] t_1;
        uint256 c_1;
    }

    struct Vote {
        bytes32 parametersHash;
        Puzzle tally;
        uint64 numVotes;
        uint64 startTime;
        uint64 endTime;
    }
    
    error InvalidProofOfExponentiation();
    error InvalidPuzzleSolution();
    error InvalidVote();

    uint256 public nextVoteId = 1;
    mapping(uint256 => Vote) votes;

    function createVote(
        PublicParameters memory pp,
        string calldata description,
        uint64 startTime,
        uint64 votingPeriod
    )
        public
    {
        // TODO: Validate public parameters?
        Vote storage newVote = votes[nextVoteId++];
        newVote.parametersHash = keccak256(abi.encode(pp));
        newVote.tally.u = 1.toUint1024();
        newVote.tally.v = 1.toUint1024();
        if (startTime == 0) {
            startTime = uint64(block.timestamp);
        } else if (startTime < block.timestamp) {
            revert();
        }
        newVote.startTime = startTime;
        newVote.endTime = startTime + votingPeriod;
    }

    function castBallot(
        uint256 voteId,
        PublicParameters memory pp,
        Puzzle memory ballot,
        ProofOfValidity memory PoV
    )
        public
    {
        Vote storage vote = votes[voteId];
        if (
            block.timestamp < vote.startTime || 
            block.timestamp > vote.endTime
        ) {
            revert();
        }
        if (keccak256(abi.encode(pp)) != vote.parametersHash) {
            revert();
        }
        verifyBallotValidity(pp, ballot, PoV);
        vote.numVotes++;
        updateTally(pp, vote.tally, ballot);
    }

    function updateTally(
        PublicParameters memory pp,
        Puzzle storage tally,
        Puzzle memory vote
    )
        private
    {
        tally.u = tally.u.mulMod2(vote.u, pp.N);
        tally.v = tally.v.mulMod2(vote.v, pp.N);
    }

    function verifyBallotValidity(
        PublicParameters memory pp,
        Puzzle memory Z,
        ProofOfValidity memory PoV
    )
        public
        view
    {
        // TODO: Check proof variables in correct domains?

        uint256 c = uint256(keccak256(abi.encode(
            PoV.a_0,
            PoV.b_0,
            PoV.a_1,
            PoV.b_1
        )));
        unchecked {
            if (PoV.c_0 + PoV.c_1 != c) {
                revert InvalidVote();
            }
        }

        uint256[4] memory lhs = pp.g.expMod(PoV.t_0, pp.N);
        uint256[4] memory rhs = PoV.a_0.mulMod2(Z.u.expMod(PoV.c_0, pp.N), pp.N);
        if (!lhs.eq(rhs)) {
            revert InvalidVote();
        }

        lhs = pp.h.expMod(PoV.t_0, pp.N);
        rhs = PoV.b_0.mulMod2(Z.v.expMod(PoV.c_0, pp.N), pp.N);
        if (!lhs.eq(rhs)) {
            revert InvalidVote();
        }

        lhs = pp.g.expMod(PoV.t_1, pp.N);
        rhs = PoV.a_1.mulMod2(Z.u.expMod(PoV.c_1, pp.N), pp.N);
        if (!lhs.eq(rhs)) {
            revert InvalidVote();
        }        

        lhs = pp.h.expMod(PoV.t_1, pp.N);
        rhs = Z.v.mulMod2(pp.yInv, pp.N).expMod(PoV.c_1, pp.N).mulMod2(PoV.b_1, pp.N);
        if (!lhs.eq(rhs)) {
            revert InvalidVote();
        }
    }

    function verifySolutionCorrectness(
        PublicParameters memory pp,
        Puzzle memory Z,
        uint256 s,
        uint256[4] memory w,
        ProofOfExponentiation memory PoE
    )
        public
        view
    {
        // TODO: Check that things are in [0, N/2]?

        verifyExponentiation(pp, Z.u, w, PoE);

        // Check v = w * y^s (mod N)
        uint256[4] memory rhs = pp.y.expMod(s, pp.N).mulMod2(w, pp.N);
        if (!Z.v.eq(rhs)) {
            // revert InvalidPuzzleSolution();
        }
    }

    function verifyExponentiation(
        PublicParameters memory pp,
        uint256[4] memory u,
        uint256[4] memory w,
        ProofOfExponentiation memory PoE
    )
        internal
        view
    {
        uint256 l = PoE.l;

        // TODO: Correct Fiat-Shamir input?
        LibPrime.checkHashToPrime(abi.encode(u, w, PoE.j), l);
        uint256 r = _expmod(2, pp.T, l); // r = 2^T (mod l)
        // Check w = π^l * u^r
        uint256[4] memory rhs = PoE.pi.expMod(l, pp.N)
            .mulMod2(u.expMod(r, pp.N), pp.N);
        if (!w.eq(rhs)) {
            // revert InvalidProofOfExponentiation();
        }
    }

    function _expmod(uint256 base, uint256 exponent, uint256 modulus)
        private
        view
        returns (uint256 result)
    {
        assembly { 
            // Get free memory pointer
            let p := mload(0x40)
            // Store parameters for the Expmod (0x05) precompile
            mstore(p, 0x20)                    // Length of Base
            mstore(add(p, 0x20), 0x20)         // Length of Exponent
            mstore(add(p, 0x40), 0x20)         // Length of Modulus
            mstore(add(p, 0x60), base)         // Base
            mstore(add(p, 0x80), exponent)     // Exponent
            mstore(add(p, 0xa0), modulus)      // Modulus
            // Call 0x05 (EXPMOD) precompile
            if iszero(staticcall(gas(), 0x05, p, 0xc0, 0, 0x20)) {
                revert(0, 0)
            }
            result := mload(0)
            // Update free memory pointer
            mstore(0x40, add(p, 0xc0))
        }
    }
}
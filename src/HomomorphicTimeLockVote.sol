pragma solidity ^0.8;

import './LibUint1024.sol';
import './LibPrime.sol';


contract HomomorphicTimeLockVote {
    using LibUint1024 for *;

    struct PublicParameters {
        uint256[4] N;
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
    error InvalidBallot();

    uint256 public nextVoteId = 1;
    mapping(uint256 => Vote) public votes;

    function createVote(
        PublicParameters memory pp,
        string calldata description,
        uint64 startTime,
        uint64 votingPeriod
    )
        public
    {
        // TODO: Validate g and y generated via Fiat-Shamir? 
        //       Validate h = g^(2^T)?
        pp.g = pp.g.normalize(pp.N);
        pp.h = pp.h.normalize(pp.N);
        pp.y = pp.y.normalize(pp.N);
        pp.yInv = pp.yInv.normalize(pp.N);
        // y * y^(-1) = 1 (mod N)
        if (!pp.y.mulMod(pp.yInv, pp.N).eq(1.toUint1024())) {
            revert();
        }

        Vote storage newVote = votes[nextVoteId++];
        newVote.parametersHash = keccak256(abi.encode(pp));

        // This instantiates the tally to 0:
        //     u = g^1 (mod N)
        //     v = h^1 * y^0 (mod N)
        // and populates the tally storage slots so subsequent SSTOREs
        // incur a gas cost of SSTORE_RESET_GAS (~5k) instead of 
        // SSTORE_SET_GAS (~20k).
        newVote.tally.u = pp.g;
        newVote.tally.v = pp.h;
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
        bytes32 parametersHash = keccak256(abi.encode(pp));
        if (parametersHash != vote.parametersHash) {
            revert();
        }
        verifyBallotValidity(pp, parametersHash, ballot, PoV);
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
        tally.u = tally.u.mulMod(vote.u, pp.N).normalize(pp.N);
        tally.v = tally.v.mulMod(vote.v, pp.N).normalize(pp.N);
    }

    function verifyBallotValidity(
        PublicParameters memory pp,
        bytes32 parametersHash,
        Puzzle memory Z,
        ProofOfValidity memory PoV
    )
        public
        view
    {
        PoV.a_0 = PoV.a_0.normalize(pp.N);
        PoV.b_0 = PoV.b_0.normalize(pp.N);
        PoV.a_1 = PoV.a_1.normalize(pp.N);
        PoV.b_1 = PoV.b_1.normalize(pp.N);

        uint256 c = uint256(keccak256(abi.encode(
            PoV.a_0,
            PoV.b_0,
            PoV.a_1,
            PoV.b_1,
            parametersHash
        )));
        unchecked {
            if (PoV.c_0 + PoV.c_1 != c) {
                revert InvalidBallot();
            }
        }

        uint256[4] memory lhs = pp.g
            .expMod(PoV.t_0, pp.N)
            .normalize(pp.N);
        uint256[4] memory rhs = Z.u
            .expMod(PoV.c_0, pp.N)
            .mulMod(PoV.a_0, pp.N)
            .normalize(pp.N);
        if (!lhs.eq(rhs)) {
            revert InvalidBallot();
        }

        lhs = pp.h
            .expMod(PoV.t_0, pp.N)
            .normalize(pp.N);
        rhs = Z.v
            .expMod(PoV.c_0, pp.N)
            .mulMod(PoV.b_0, pp.N)
            .normalize(pp.N);
        if (!lhs.eq(rhs)) {
            revert InvalidBallot();
        }

        lhs = pp.g
            .expMod(PoV.t_1, pp.N)
            .normalize(pp.N);
        rhs = Z.u
            .expMod(PoV.c_1, pp.N)
            .mulMod(PoV.a_1, pp.N)
            .normalize(pp.N);
        if (!lhs.eq(rhs)) {
            revert InvalidBallot();
        }

        lhs = pp.h
            .expMod(PoV.t_1, pp.N)
            .normalize(pp.N);
        rhs = Z.v
            .mulMod(pp.yInv, pp.N)
            .expMod(PoV.c_1, pp.N)
            .mulMod(PoV.b_1, pp.N)
            .normalize(pp.N);
        if (!lhs.eq(rhs)) {
            revert InvalidBallot();
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
        w = w.normalize(pp.N);

        bytes32 parametersHash = keccak256(abi.encode(pp));
        verifyExponentiation(pp, parametersHash, Z.u, w, PoE);

        // Check v = w * y^s (mod N)
        uint256[4] memory rhs = pp.y
            .expMod(s, pp.N)
            .mulMod(w, pp.N)
            .normalize(pp.N);
        if (!Z.v.eq(rhs)) {
            revert InvalidPuzzleSolution();
        }
    }

    function verifyExponentiation(
        PublicParameters memory pp,
        bytes32 parametersHash,
        uint256[4] memory u,
        uint256[4] memory w,
        ProofOfExponentiation memory PoE
    )
        internal
        view
    {
        uint256 l = PoE.l;
        LibPrime.checkHashToPrime(abi.encode(u, w, parametersHash, PoE.j), l);

        uint256 r = _expMod(2, pp.T, l); // r = 2^T (mod l)
        // Check w = π^l * u^r
        uint256[4] memory rhs = PoE.pi
            .expMod(l, pp.N)
            .mulMod(u.expMod(r, pp.N), pp.N)
            .normalize(pp.N);
        if (!w.eq(rhs)) {
            revert InvalidProofOfExponentiation();
        }
    }

    function _expMod(uint256 base, uint256 exponent, uint256 modulus)
        private
        view
        returns (uint256 result)
    {
        assembly { 
            // Get free memory pointer
            let p := mload(0x40)
            // Store parameters for the EXPMOD (0x05) precompile
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
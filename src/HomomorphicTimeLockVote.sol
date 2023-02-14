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
    
    error InvalidProofOfExponentiation();
    error InvalidPuzzleSolution();
    error InvalidVote();

    function verifyVoteValidity(
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
        rhs = PoV.b_1.mulMod2(Z.v.mulMod2(pp.yInv, pp.N).expMod(PoV.c_1, pp.N), pp.N);
        if (!lhs.eq(rhs)) {
            // revert InvalidVote();
        }
    }

    function verifySolutionCorrectness(
        PublicParameters memory pp,
        Puzzle memory Z,
        uint256[4] memory s,
        uint256[4] memory w,
        ProofOfExponentiation memory PoE
    )
        public
        view
    {
        // TODO: Check that things are in [0, N/2]?

        verifyExponentiation(pp, Z.u, w, PoE);

        uint256[4] memory N = pp.N;
        uint256[4] memory y = pp.y;
        uint256[4] memory v = Z.v;

        // Check v = w * y^s (mod N)
        uint256[4] memory lhs = v.addMod(v, N).addMod(v, N).addMod(v, N); // TODO: optimize
        uint256[4] memory rhs = w.mulMod(y.expMod(s, N), N);
        if (!lhs.eq(rhs)) {
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
        uint256[4] memory N = pp.N;
        uint256 l = PoE.l;

        // TODO: Correct Fiat-Shamir input?
        LibPrime.checkHashToPrime(abi.encode(w, PoE.j), l);
        uint256 r = _expmod(2, pp.T, PoE.l); // r = 2^T (mod l)
        // Check 4w = 4 * π^l * u^r
        uint256[4] memory lhs = w.addMod(w, N).addMod(w, N).addMod(w, N); // TODO: optimize
        uint256[4] memory rhs = PoE.pi.expMod(l, N).mulMod(u.expMod(r, N), N);
        if (!lhs.eq(rhs)) {
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
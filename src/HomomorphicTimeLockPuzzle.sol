pragma solidity ^0.8;

import './LibBigMath.sol';
import './LibPrime.sol';

contract HomomorphicTimeLockPuzzle {
    using LibBigMath for *;

    struct PublicParameters {
        uint256[8] N;
        uint256[8] NPlus1;
        uint256[8] halfN;
        uint256[16] NSquared;
        uint256 T;
        uint256[8] g;
        uint256[8] h;
    }

    struct Puzzle {
        uint256[8] u;
        uint256[16] v;
    }

    struct ProofOFExponentiation {
        uint256[8] pi;
        uint256 j;
        uint256 l;
    }

    // valid vote
    // valid puzzle
    // valid solution

    error InvalidProofOfExponentiation();
    error InvalidPuzzleSolution();

    function verifySolution(
        PublicParameters memory pp,
        Puzzle memory Z,
        uint256[8] memory s,
        uint256[8] memory w,
        ProofOFExponentiation memory PoE
    )
        public
        view
    {
        // TODO: Check that things are in [0, N/2]

        verifyExponentiation(pp, Z.u, w, PoE);

        // Check 4v = 4 * w^N * (1 + N)^s (mod N^2)
        // uint256[8] memory lhs = Z.v
            // .addMod(Z.v, pp.NSquared)
            // .addMod(Z.v, pp.NSquared)
            // .addMod(Z.v, pp.NSquared);
        // uint256[8] memory rhs = w.expMod(pp.N, pp.NSquared)
        //     .mulMod(pp.NPlus1.expMod(s, pp.NSquared), pp.NSquared);
        // if (!lhs.eq(rhs)) {
        //     revert InvalidPuzzleSolution();
        // }
    }

    function verifyExponentiation(
        PublicParameters memory pp,
        uint256[8] memory u,
        uint256[8] memory w,
        ProofOFExponentiation memory PoE
    )
        internal
        view
    {
        uint256[8] memory N = pp.N;
        uint256 l = PoE.l;

        // TODO: Correct Fiat-Shamir input?
        LibPrime.checkHashToPrime(abi.encode(w, PoE.j), l);
        uint256 r = _expmod(2, pp.T, PoE.l); // r = 2^T (mod l)
        // Check 4w = 4 * π^l * u^r
        uint256[8] memory lhs = w.addMod(w, N).addMod(w, N).addMod(w, N); // TODO: optimize
        uint256[8] memory rhs = PoE.pi.expMod(l, N).mulMod(u.expMod(r, N), N);
        if (!lhs.eq(rhs)) {
            revert InvalidProofOfExponentiation();
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
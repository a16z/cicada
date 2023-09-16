// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8;

import './CicadaCumulativeVote.sol';
import './LibUint1024.sol';
import './LibPrime.sol';

library LibSigmaProtocol {
    using LibUint1024 for *;

    struct ProverMessage1 {
        uint256[4] A1;
        uint256[4] A2;
        uint256[4] A;
    }

    struct ProverMessage2 {
        uint256[4] x1;
        uint256[4] x2;
        uint256[4] w1;
        uint256[4] w2;
        uint256[4] w;
        bool wIsNegative;
        bool w2IsNegative;
    }

    struct ProofOfSquare {
        uint256[4] squareRoot;
        uint256[4] quotient;
        ProverMessage1 p1;
        ProverMessage2 p2;
    }

    struct ProofOfEquality {
        uint256[4] quotient;
        ProverMessage1 p1;
        ProverMessage2 p2;
    }

    struct ProofOfPositivity {
        uint256[4][3] squareDecomposition;
        ProofOfSquare[3] PoKSqS;
        ProofOfEquality PoKSEq;
    }

    struct ProofOfPuzzleValidity {
        uint256[4] a;
        uint256[4] b;
        uint256[4] alpha;
        uint256[4] beta;
    }

    struct ProofOfExponentiation {
        uint256[4] pi;
        uint256 j;
        uint256 l;
    }

    // Verifies the Wesolowski proof of exponentiation that:
    //     u^(2^T) = w (mod N)
    // See Section 2.1 of http://crypto.stanford.edu/~dabo/papers/VDFsurvey.pdf
    function verifyExponentiation(
        CicadaCumulativeVote.PublicParameters memory pp,
        bytes32 parametersHash,
        uint256[4] memory u,
        uint256[4] memory w,
        ProofOfExponentiation memory PoE
    )
        internal
        view
    {
        w = w.normalize(pp.N);
        // Fiat-Shamir random prime
        uint256 l = PoE.l;
        LibPrime.checkHashToPrime(abi.encode(u, w, parametersHash, PoE.j), l);

        uint256 r = _expMod(2, pp.T, l); // r = 2^T (mod l)
        // Check w = π^l * u^r (mod N)
        uint256[4] memory rhs = PoE.pi
            .expMod(l, pp.N)
            .mulMod(u.expMod(r, pp.N), pp.N)
            .normalize(pp.N);
        require(w.eq(rhs));
    }

    function verifyProofOfPuzzleValidity(
        CicadaCumulativeVote.PublicParameters memory pp,
        bytes32 parametersHash,
        CicadaCumulativeVote.Puzzle memory Z,
        ProofOfPuzzleValidity memory PoPV
    )
        internal
        view
    {
        uint256 e = uint256(keccak256(abi.encode(
            PoPV.a, 
            PoPV.b, 
            parametersHash
        )));

        uint256[4] memory lhs = pp.g
            .expMod(PoPV.alpha, pp.N)
            .normalize(pp.N);
        uint256[4] memory rhs = Z.u
            .expMod(e, pp.N)
            .mulMod(PoPV.a, pp.N)
            .normalize(pp.N);
        require(lhs.eq(rhs));

        lhs = pp.h
            .expMod(PoPV.alpha, pp.N)
            .mulMod(pp.y.expMod(PoPV.beta, pp.N), pp.N)
            .normalize(pp.N);
        rhs = Z.v
            .expMod(e, pp.N)
            .mulMod(PoPV.b, pp.N)
            .normalize(pp.N);
        require(lhs.eq(rhs));
    }

    function verifyProofOfPositivity(
        CicadaCumulativeVote.PublicParameters memory pp,
        bytes32 parametersHash,
        CicadaCumulativeVote.Puzzle memory Z,
        ProofOfPositivity memory PoPosS
    )
        internal
        view
    {
        verifyProofOfSquare(
            pp, 
            parametersHash, 
            PoPosS.squareDecomposition[0], 
            PoPosS.PoKSqS[0]
        );
        verifyProofOfSquare(
            pp, 
            parametersHash, 
            PoPosS.squareDecomposition[1], 
            PoPosS.PoKSqS[1]
        );
        verifyProofOfSquare(
            pp, 
            parametersHash, 
            PoPosS.squareDecomposition[2], 
            PoPosS.PoKSqS[2]
        );

        uint256[4] memory legendre;
        // v^4 * y = h^(4r) * y^(4s+1)
        legendre = Z.v.expMod(4, pp.N).mulMod(pp.y, pp.N).normalize(pp.N);

        uint256[4] memory sumOfSquares;
        sumOfSquares = PoPosS.squareDecomposition[0]
            .mulMod(PoPosS.squareDecomposition[1], pp.N)
            .mulMod(PoPosS.squareDecomposition[2], pp.N)
            .normalize(pp.N);

        verifyProofOfEquality(
            pp, 
            parametersHash, 
            sumOfSquares, 
            legendre,
            PoPosS.PoKSEq
        );
    }

    function verifyProofOfSquare(
        CicadaCumulativeVote.PublicParameters memory pp,
        bytes32 parametersHash,
        uint256[4] memory squarePuzzle,
        ProofOfSquare memory PoKSqS
    )
        internal
        view
    {
        uint256[4] memory Z1 = PoKSqS.squareRoot;
        uint256[4] memory Z2 = squarePuzzle;

        // quotient := Z1 / Z2
        require(Z1.eq(
            PoKSqS.quotient.mulMod(Z2, pp.N).normalize(pp.N)
        ));

        uint256 e = uint256(keccak256(abi.encode(PoKSqS.p1, parametersHash)));

        uint256[4] memory lhs = Z1.expMod(e, pp.N)
            .mulMod(PoKSqS.p1.A1, pp.N)
            .normalize(pp.N);
        uint256[4] memory rhs = pp.h.expMod(PoKSqS.p2.w1, pp.N)
            .mulMod(pp.y.expMod(PoKSqS.p2.x1, pp.N), pp.N)
            .normalize(pp.N);
        require(lhs.eq(rhs));

        lhs = Z2.expMod(e, pp.N)
            .mulMod(PoKSqS.p1.A2, pp.N)
            .normalize(pp.N);
        if (PoKSqS.p2.w2IsNegative) {
            rhs = pp.hInv.expMod(PoKSqS.p2.w2, pp.N)
                .mulMod(Z1.expMod(PoKSqS.p2.x2, pp.N), pp.N)
                .normalize(pp.N);
        } else {
            rhs = pp.h.expMod(PoKSqS.p2.w2, pp.N)
                .mulMod(Z1.expMod(PoKSqS.p2.x2, pp.N), pp.N)
                .normalize(pp.N);
        }
        require(lhs.eq(rhs));

        lhs = PoKSqS.quotient.expMod(e, pp.N)
            .mulMod(PoKSqS.p1.A, pp.N)
            .normalize(pp.N);
        if (PoKSqS.p2.wIsNegative) {
            rhs = pp.hInv.expMod(PoKSqS.p2.w, pp.N).normalize(pp.N);
        } else {
            rhs = pp.h.expMod(PoKSqS.p2.w, pp.N).normalize(pp.N);
        }
        // require(lhs.eq(rhs));
    }

    function verifyProofOfEquality(
        CicadaCumulativeVote.PublicParameters memory pp,
        bytes32 parametersHash,
        uint256[4] memory Z1,
        uint256[4] memory Z2,
        ProofOfEquality memory PoKSEq
    )
        internal
        view
    {
        // quotient := Z1 / Z2
        require(Z1.eq(
            PoKSEq.quotient.mulMod(Z2, pp.N).normalize(pp.N)
        ));

        uint256 e = uint256(keccak256(abi.encode(PoKSEq.p1, parametersHash)));

        uint256[4] memory lhs = Z1.expMod(e, pp.N)
            .mulMod(PoKSEq.p1.A1, pp.N)
            .normalize(pp.N);
        uint256[4] memory rhs = pp.h.expMod(PoKSEq.p2.w1, pp.N)
            .mulMod(pp.y.expMod(PoKSEq.p2.x1, pp.N), pp.N)
            .normalize(pp.N);
        require(lhs.eq(rhs));

        lhs = Z2.expMod(e, pp.N)
            .mulMod(PoKSEq.p1.A2, pp.N)
            .normalize(pp.N);
        rhs = pp.h.expMod(PoKSEq.p2.w2, pp.N)
            .mulMod(pp.y.expMod(PoKSEq.p2.x2, pp.N), pp.N)
            .normalize(pp.N);
        require(lhs.eq(rhs));

        lhs = PoKSEq.quotient.expMod(e, pp.N)
            .mulMod(PoKSEq.p1.A, pp.N)
            .normalize(pp.N);
        if (PoKSEq.p2.wIsNegative) {
            rhs = pp.hInv.expMod(PoKSEq.p2.w, pp.N).normalize(pp.N);
        } else {
            rhs = pp.h.expMod(PoKSEq.p2.w, pp.N).normalize(pp.N);
        }
        require(lhs.eq(rhs));
    }

    // Computes (base ** exponent) % modulus
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
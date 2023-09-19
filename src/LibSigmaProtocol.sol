// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8;

import './LibUint1024.sol';
import './LibPrime.sol';

library LibSigmaProtocol {
    using LibUint1024 for *;

    struct ProofOfSquare {
        uint256[4] squareRoot;
        uint256[4] A1;
        uint256[4] A2;
        uint256[4] x;
        uint256[4] w1;
        uint256[4] w2;
        bool w2IsNegative;
    }

    struct ProofOfEquality {
        uint256[4] A1;
        uint256[4] A2;
        uint256[4] x;
        uint256[4] w1;
        uint256[4] w2;
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
        uint256 T,
        uint256[4] memory N,
        bytes32 parametersHash,
        uint256[4] memory u,
        uint256[4] memory w,
        ProofOfExponentiation memory PoE
    )
        internal
        view
    {
        w = w.normalize(N);
        // Fiat-Shamir random prime
        uint256 l = PoE.l;
        LibPrime.checkHashToPrime(abi.encode(u, w, parametersHash, PoE.j), l);

        uint256 r = _expMod(2, T, l); // r = 2^T (mod l)
        // Check w = π^l * u^r (mod N)
        uint256[4] memory rhs = PoE.pi
            .expMod(l, N)
            .mulMod(u.expMod(r, N), N)
            .normalize(N);
        require(w.eq(rhs), "proof of exponentiation");
    }

    function verifyProofOfPuzzleValidity(
        uint256[4] memory N,
        uint256[4] memory g,
        uint256[4] memory h,
        uint256[4] memory y,
        bytes32 parametersHash,
        uint256[4] memory u,
        uint256[4] memory v,
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

        uint256[4] memory lhs = g
            .expMod(PoPV.alpha, N)
            .normalize(N);
        uint256[4] memory rhs = u
            .expMod(e, N)
            .mulMod(PoPV.a, N)
            .normalize(N);
        require(lhs.eq(rhs), "proof of puzzle validity");

        lhs = h
            .expMod(PoPV.alpha, N)
            .mulMod(y.expMod(PoPV.beta, N), N)
            .normalize(N);
        rhs = v
            .expMod(e, N)
            .mulMod(PoPV.b, N)
            .normalize(N);
        require(lhs.eq(rhs), "proof of puzzle validity");
    }

    function verifyProofOfPositivity(
        uint256[4] memory N,
        uint256[4] memory h,
        uint256[4] memory hInv,
        uint256[4] memory y,
        bytes32 parametersHash,
        uint256[4] memory v,
        ProofOfPositivity memory PoPosS
    )
        internal
        view
    {
        verifyProofOfSquare(
            N, h, hInv, y, 
            parametersHash, 
            PoPosS.squareDecomposition[0], 
            PoPosS.PoKSqS[0]
        );
        verifyProofOfSquare(
            N, h, hInv, y,
            parametersHash, 
            PoPosS.squareDecomposition[1], 
            PoPosS.PoKSqS[1]
        );
        verifyProofOfSquare(
            N, h, hInv, y,
            parametersHash, 
            PoPosS.squareDecomposition[2], 
            PoPosS.PoKSqS[2]
        );

        uint256[4] memory legendre;
        // v^4 * y = h^(4r) * y^(4s+1)
        legendre = v.expMod(4, N).mulMod(y, N).normalize(N);

        uint256[4] memory sumOfSquares;
        sumOfSquares = PoPosS.squareDecomposition[0]
            .mulMod(PoPosS.squareDecomposition[1], N)
            .mulMod(PoPosS.squareDecomposition[2], N)
            .normalize(N);

        verifyProofOfEquality(
            N, h, y,
            parametersHash, 
            sumOfSquares, 
            legendre,
            PoPosS.PoKSEq
        );
    }

    function verifyProofOfSquare(
        uint256[4] memory N,
        uint256[4] memory h,
        uint256[4] memory hInv,
        uint256[4] memory y,
        bytes32 parametersHash,
        uint256[4] memory squarePuzzle,
        ProofOfSquare memory PoKSqS
    )
        internal
        view
    {
        uint256[4] memory v1 = PoKSqS.squareRoot;
        uint256[4] memory v2 = squarePuzzle;

        uint256 e = uint256(keccak256(abi.encode(PoKSqS.A1, PoKSqS.A2, parametersHash)));

        uint256[4] memory lhs = v1.expMod(e, N)
            .mulMod(PoKSqS.A1, N)
            .normalize(N);
        uint256[4] memory rhs = h.expMod(PoKSqS.w1, N)
            .mulMod(y.expMod(PoKSqS.x, N), N)
            .normalize(N);
        require(lhs.eq(rhs), "proof of square");

        lhs = v2.expMod(e, N)
            .mulMod(PoKSqS.A2, N)
            .normalize(N);
        if (PoKSqS.w2IsNegative) {
            rhs = hInv.expMod(PoKSqS.w2, N)
                .mulMod(v1.expMod(PoKSqS.x, N), N)
                .normalize(N);
        } else {    
            rhs = h.expMod(PoKSqS.w2, N)
                .mulMod(v1.expMod(PoKSqS.x, N), N)
                .normalize(N);
        }
        require(lhs.eq(rhs), "proof of square");
    }

    function verifyProofOfEquality(
        uint256[4] memory N,
        uint256[4] memory h,
        uint256[4] memory y,
        bytes32 parametersHash,
        uint256[4] memory v1,
        uint256[4] memory v2,
        ProofOfEquality memory PoKSEq
    )
        internal
        view
    {
        uint256 e = uint256(keccak256(abi.encode(PoKSEq.A1, PoKSEq.A2, parametersHash)));

        uint256[4] memory lhs = v1.expMod(e, N)
            .mulMod(PoKSEq.A1, N)
            .normalize(N);
        uint256[4] memory rhs = h.expMod(PoKSEq.w1, N)
            .mulMod(y.expMod(PoKSEq.x, N), N)
            .normalize(N);
        require(lhs.eq(rhs), "proof of equality");

        lhs = v2.expMod(e, N)
            .mulMod(PoKSEq.A2, N)
            .normalize(N);
        rhs = h.expMod(PoKSEq.w2, N)
            .mulMod(y.expMod(PoKSEq.x, N), N)
            .normalize(N);
        require(lhs.eq(rhs), "proof of equality");
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
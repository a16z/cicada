// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8;

import './CicadaVote.sol';
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

    function verifyProofOfPositivity(
        CicadaVote.PublicParameters memory pp,
        bytes32 parametersHash,
        CicadaVote.Puzzle memory Z,
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
        CicadaVote.PublicParameters memory pp,
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
        CicadaVote.PublicParameters memory pp,
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
}
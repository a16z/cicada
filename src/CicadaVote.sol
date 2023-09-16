// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8;

import './LibUint1024.sol';
import './LibPrime.sol';
import './LibSigmaProtocol.sol';


/// @dev The Cicada base contract. Note that the `createVote` and 
///      `castBallot` functions assume that access control is implemented
///      by the inheriting contract.
abstract contract CicadaVote {
    using LibUint1024 for *;

    struct PublicParameters {
        uint256 T;
        uint256[4] N;
        uint256[4] g;
        uint256[4] h;
        uint256[4] hInv;
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
        LibSigmaProtocol.ProofOfPositivity[] PoPosS;
        uint256 R;
    }

    struct Vote {
        bytes32 parametersHash;
        Puzzle[] tallies;
        uint64 pointsPerVoter;
        uint64 startTime;
        uint64 endTime;
        bool isFinalized;
    }

    event VoteCreated(
        uint256 voteId,
        string description,
        uint64 pointsPerVoter,
        uint64 startTime,
        uint64 endTime,
        PublicParameters pp
    );

    event VoteFinalized(
        uint256 voteId,
        uint256[] pointsPerChoice
    );
    
    error InvalidProofOfExponentiation();
    error InvalidPuzzleSolution();
    error InvalidBallot();
    error InvalidStartTime();
    error VoteIsNotOngoing();
    error VoteHasNotEnded();
    error VoteAlreadyFinalized();
    error ParametersHashMismatch();

    uint256 public nextVoteId = 1;
    mapping(uint256 => Vote) public votes;

    /// @dev Creates a vote using the given public parameters.
    ///      CAUTION: This function does not check the validity of 
    ///      the public parameters! Most notably, it does not check
    ///          1. that pp.N is a valid RSA modulus, 
    ///          2. that h = g^(2^T), 
    ///          3. or that g and y have Jacobi symbol 1. 
    ///      These should be verified off-chain (or in the inheriting
    ///      contract, if desired).
    /// @param pp Public parameters for the homomorphic time-lock puzzles.
    /// @param description A human-readable description of the vote.
    /// @param pointsPerVoter TODO
    /// @param startTime The UNIX timestamp at which voting opens.
    /// @param votingPeriod The duration of the voting period, in seconds.
    /// @param numChoices TODO
    function _createVote(
        PublicParameters memory pp,
        string memory description,
        uint64 pointsPerVoter,
        uint64 startTime,
        uint64 votingPeriod,
        uint256 numChoices
    )
        internal
    {
        pp.g = pp.g.normalize(pp.N);
        pp.h = pp.h.normalize(pp.N);
        pp.hInv = pp.hInv.normalize(pp.N);
        // h * h^(-1) = 1 (mod N)
        if (!pp.h.mulMod(pp.hInv, pp.N).eq(1.toUint1024())) {
            revert();
        }
        pp.y = pp.y.normalize(pp.N);
        pp.yInv = pp.yInv.normalize(pp.N);
        // y * y^(-1) = 1 (mod N)
        if (!pp.y.mulMod(pp.yInv, pp.N).eq(1.toUint1024())) {
            revert();
        }

        uint256 voteId = nextVoteId++;
        Vote storage newVote = votes[voteId];
        newVote.parametersHash = keccak256(abi.encode(pp));

        for (uint256 i = 0; i != numChoices; i++) {
            // This instantiates the tally to 0:
            //     u = g^1 (mod N)
            //     v = h^1 * y^0 (mod N)
            // and populates the tally storage slots so subsequent SSTOREs
            // incur a gas cost of SSTORE_RESET_GAS (~5k) instead of 
            // SSTORE_SET_GAS (~20k).
            newVote.tallies[i].u = pp.g;
            newVote.tallies[i].v = pp.h;
        }

        if (startTime == 0) {
            startTime = uint64(block.timestamp);
        } else if (startTime < block.timestamp) {
            revert InvalidStartTime();
        }
        newVote.startTime = startTime;
        uint64 endTime = startTime + votingPeriod;
        newVote.endTime = endTime;

        emit VoteCreated(
            voteId,
            description,
            pointsPerVoter,
            startTime,
            endTime,
            pp
        );
    }

    /// @dev Casts a ballot for an active vote.
    /// @param voteId The vote to cast a ballot for.
    /// @param pp The public parameters used for the vote.
    /// @param ballot The time-lock puzzle encoding the ballot.
    /// @param PoV The proof of ballot validity.
    function _castBallot(
        uint256 voteId,
        PublicParameters memory pp,
        Puzzle[] memory ballot,
        ProofOfValidity memory PoV
    )
        internal
    {
        Vote storage vote = votes[voteId];
        if (
            block.timestamp < vote.startTime || 
            block.timestamp > vote.endTime
        ) {
            revert VoteIsNotOngoing();
        }

        // Ballot must have one puzzle per choice.
        if (ballot.length != vote.tallies.length) {
            revert InvalidBallot();
        }
        bytes32 parametersHash = keccak256(abi.encode(pp));
        if (parametersHash != vote.parametersHash) {
            revert ParametersHashMismatch();
        }
        parametersHash = keccak256(abi.encode(parametersHash, msg.sender));

        _verifyBallotValidity(
            pp, 
            parametersHash, 
            ballot, 
            PoV, 
            vote.pointsPerVoter
        );

        for (uint256 i = 0; i != ballot.length; i++) {
            _updateTally(pp, vote.tallies[i], ballot[i]);
        }
    }

    /// @dev Finalizes a vote by supplying supplying the decoded tallies
    ///      `talliesPlaintext` and associated proof of correctness.
    /// @param voteId The vote to cast a ballot for.
    /// @param pp The public parameters used for the vote.
    /// @param talliesPlaintext The purported plaintext vote tallies.
    /// @param w The purported value `w := Z.u^(2^T)`, where Z
    ///          is the puzzle encoding the tally.
    /// @param PoE The Wesolowski proof of exponentiation (i.e. the 
    ///        proof that `w = Z.u^(2^T)`)
    function _finalizeVote(
        uint256 voteId,
        PublicParameters memory pp,
        uint256[] memory talliesPlaintext,
        uint256[4][] memory w,
        ProofOfExponentiation[] memory PoE
    )
        internal
    {
        Vote storage vote = votes[voteId];
        if (block.timestamp < vote.endTime) {
            revert VoteHasNotEnded();
        }
        bytes32 parametersHash = keccak256(abi.encode(pp));
        if (parametersHash != vote.parametersHash) {
            revert ParametersHashMismatch();
        }
        
        if (vote.isFinalized) {
            revert VoteAlreadyFinalized();
        }
        
        Puzzle[] memory tallies = vote.tallies;
        if (
            tallies.length != talliesPlaintext.length ||
            talliesPlaintext.length != w.length ||
            w.length != PoE.length
        ) {
            revert("Array length mismatch");
        }

        for (uint256 i = 0; i != tallies.length; i++) {
            _verifySolutionCorrectness(
                pp,
                parametersHash,
                tallies[i],
                talliesPlaintext[i],
                w[i],
                PoE[i]
            );
        }

        vote.isFinalized = true;

        emit VoteFinalized(
            voteId,
            talliesPlaintext
        );
    }

    /// @dev TODO
    /// @param pp The public parameters used for the vote.
    /// @param parametersHash The hash of `pp`.
    /// @param ballot TODO
    /// @param PoV The proof of ballot validity.
    /// @param pointsPerVoter TODO
    function _verifyBallotValidity(
        PublicParameters memory pp,
        bytes32 parametersHash,
        Puzzle[] memory ballot,
        ProofOfValidity memory PoV,
        uint64 pointsPerVoter
    )
        internal
        view
    {
        if (ballot.length != PoV.PoPosS.length) {
            revert InvalidBallot();
        }

        // Check that ballot puzzles sum to `pointsPerVoter`
        // \product_i v_i = h^{\sum_i r_i} * y^{\sum_i s_i}
        //               ?= h^R * y^pointsPerVoter
        uint256[4] memory vProduct = ballot[0].v;
        for (uint256 i = 1; i != ballot.length; i++) {
            vProduct = vProduct.mulMod(ballot[i].v, pp.N);
        }
        uint256[4] memory rhs = pp.h.expMod(PoV.R, pp.N)
            .mulMod(pp.y.expMod(pointsPerVoter, pp.N), pp.N);
        if (!vProduct.normalize(pp.N).eq(rhs.normalize(pp.N))) {
            revert InvalidBallot();
        }
        
        // Check that each ballot puzzle encodes a positive 
        // value
        for (uint256 i = 0; i != ballot.length; i++) {
            LibSigmaProtocol.verifyProofOfPositivity(
                pp, 
                parametersHash, 
                ballot[i], 
                PoV.PoPosS[i]
            );
        }

        // Check that u and v are consistent
    }

    /// @dev Verifies that `s` is the plaintext tally encoded in the 
    ///      homomorphic timelock puzzle `Z`. 
    /// @param pp The public parameters used for the vote.
    /// @param Z The time-lock puzzle encoding the tally. 
    /// @param s The purported plaintext tally encoded by `Z`.
    /// @param w The purported value `w := Z.u^(2^T)`. 
    /// @param PoE The Wesolowski proof of exponentiation (i.e. the 
    ///        proof that `w = Z.u^(2^T)`)
    function _verifySolutionCorrectness(
        PublicParameters memory pp,
        bytes32 parametersHash,
        Puzzle memory Z,
        uint256 s,
        uint256[4] memory w,
        ProofOfExponentiation memory PoE
    )
        internal
        view
    {
        _verifyExponentiation(pp, parametersHash, Z.u, w, PoE);

        // Check v = w * y^s (mod N)
        uint256[4] memory rhs = pp.y
            .expMod(s, pp.N)
            .mulMod(w, pp.N)
            .normalize(pp.N);
        if (!Z.v.eq(rhs)) {
            revert InvalidPuzzleSolution();
        }
    }

    // Verifies the Wesolowski proof of exponentiation that:
    //     u^(2^T) = w (mod N)
    // See Section 2.1 of http://crypto.stanford.edu/~dabo/papers/VDFsurvey.pdf
    function _verifyExponentiation(
        PublicParameters memory pp,
        bytes32 parametersHash,
        uint256[4] memory u,
        uint256[4] memory w,
        ProofOfExponentiation memory PoE
    )
        private
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
        if (!w.eq(rhs)) {
            revert InvalidProofOfExponentiation();
        }
    }

    // Homomorphically adds the ballot value to the tally.
    function _updateTally(
        PublicParameters memory pp,
        Puzzle storage tally,
        Puzzle memory ballot
    )
        private
    {
        tally.u = tally.u.mulMod(ballot.u, pp.N).normalize(pp.N);
        tally.v = tally.v.mulMod(ballot.v, pp.N).normalize(pp.N);
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
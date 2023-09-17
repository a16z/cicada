// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8;

import './LibUint1024.sol';
import './LibPrime.sol';


/// @dev Cicada auction base contract. Note that `_createAuction`, `_placeBid`,
///      and `_finalizeAuction` assume asset escrow/transfers are implemented by
///      the inheriting contract.
abstract contract CicadaAuction {
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

    struct BidderInfo {
        uint32 id;
        bool hasBid;
    }

    struct Auction {
        bytes32 parametersHash;
        uint64 startTime;
        uint64 endTime;
        bool isFinalized;
        Puzzle[] tallies;
        mapping(address => BidderInfo) bidders;
    }
    
    error InvalidProofOfExponentiation();
    error InvalidPuzzleSolution();
    error InvalidBid();
    error InvalidStartTime();
    error AuctionIsNotOngoing();
    error AuctionHasNotEnded();
    error AuctionAlreadyFinalized();
    error ParametersHashMismatch();

    uint256 public nextAuctionId = 1;
    mapping(uint256 => Auction) public auctions;

    uint256 private constant MAX_NUM_BIDDERS = 64;

    function _createAuction(
        PublicParameters memory pp,
        uint64 startTime,
        uint64 bidPeriod,
        address[] memory bidders,
        uint256 numBidBits
    )
        internal
    {
        require(bidders.length <= MAX_NUM_BIDDERS, "Too many bidders");

        pp.g = pp.g.normalize(pp.N);
        pp.h = pp.h.normalize(pp.N);
        pp.y = pp.y.normalize(pp.N);
        pp.yInv = pp.yInv.normalize(pp.N);
        // y * y^(-1) = 1 (mod N)
        if (!pp.y.mulMod(pp.yInv, pp.N).eq(1.toUint1024())) {
            revert();
        }

        uint256 auctionId = nextAuctionId++;
        Auction storage newAuction = auctions[auctionId];
        newAuction.parametersHash = keccak256(abi.encode(pp));

        for (uint256 i = 0; i != numBidBits; i++) {
            newAuction.tallies.push(Puzzle(pp.g, pp.h));
        }
        for (uint256 i = 0; i != bidders.length; i++) {
            newAuction.bidders[bidders[i]] = BidderInfo(uint32(i + 1), false);
        }

        if (startTime == 0) {
            startTime = uint64(block.timestamp);
        } else if (startTime < block.timestamp) {
            revert InvalidStartTime();
        }
        newAuction.startTime = startTime;
        uint64 endTime = startTime + bidPeriod;
        newAuction.endTime = endTime;
    }

    function _placeBid(
        uint256 auctionId,
        PublicParameters memory pp,
        Puzzle[] memory bid,
        ProofOfValidity[] memory validityProofs
    )
        internal
    {
        Auction storage auction = auctions[auctionId];
        if (
            block.timestamp < auction.startTime || 
            block.timestamp > auction.endTime
        ) {
            revert AuctionIsNotOngoing();
        }

        require(!auction.bidders[msg.sender].hasBid, "Bidder has already bid");
        uint256 bidderId = uint256(auction.bidders[msg.sender].id);
        require(bidderId != 0, "Unregistered bidder");

        bytes32 parametersHash = keccak256(abi.encode(pp));
        if (parametersHash != auction.parametersHash) {
            revert ParametersHashMismatch();
        }
        parametersHash = keccak256(abi.encode(parametersHash, msg.sender));
        
        uint256[4] memory yInvS = pp.yInv.expMod(1 << (bidderId - 1), pp.N);

        require(bid.length == validityProofs.length, "Array length mismatch");
        for (uint256 i = 0; i != bid.length; i++) {
            _verifyBallotValidity(
                pp, 
                parametersHash, 
                bid[i], 
                validityProofs[i], 
                yInvS
            );
            _updateTally(pp, auction.tallies[i], bid[i]);
        }

        auction.bidders[msg.sender].hasBid = true;
    }

    function _finalizeAuction(
        uint256 auctionId,
        PublicParameters memory pp,
        address winner,
        uint256[] memory plaintextTallies,
        uint256[4][] memory w,
        ProofOfExponentiation[] memory PoE
    )
        internal
    {
        Auction storage auction = auctions[auctionId];
        if (block.timestamp < auction.endTime) {
            revert AuctionHasNotEnded();
        }
        bytes32 parametersHash = keccak256(abi.encode(pp));
        if (parametersHash != auction.parametersHash) {
            revert ParametersHashMismatch();
        }
        
        if (auction.isFinalized) {
            revert AuctionAlreadyFinalized();
        }

        require(plaintextTallies.length <= auction.tallies.length);
        require(
            plaintextTallies.length == w.length &&
            w.length == PoE.length
        );

        uint256 remainingBiddersBitvector = (1 << MAX_NUM_BIDDERS) - 1;
        for (uint256 i = 0; i != plaintextTallies.length; i++) {
            _verifySolutionCorrectness(
                pp,
                parametersHash,
                auction.tallies[i],
                plaintextTallies[i],
                w[i],
                PoE[i]
            );

            if (remainingBiddersBitvector & plaintextTallies[i] == 0) {
                continue;
            }
            remainingBiddersBitvector &= plaintextTallies[i];
        }

        if (remainingBiddersBitvector & (remainingBiddersBitvector - 1) == 0) {
            // Exactly one bit set => winner
            
            // Check that the provided `winner` address is correct
            // (reverts if `winner` is not a registered bidder, i.e. id is 0)
            require((1 << (auction.bidders[winner].id - 1)) == remainingBiddersBitvector);
            
        } else {
            // All puzzles must be checked if there is a tie
            require(plaintextTallies.length == auction.tallies.length);
            // Can pick any one of the remaining bidders as the winner
            // (can be replaced with preferred tie-breaking logic)
            require((1 << (auction.bidders[winner].id - 1) & remainingBiddersBitvector) != 0);
        }

        auction.isFinalized = true;
    }

    /// @dev OR composition of two DLOG equality sigma protocols:
    ///          DLOG_g(u) = DLOG_h(v) OR DLOG_g(u) = DLOG(v / y^(2^i))
    ///      This is equivalent to proving that there exists some
    ///      value r such that:
    ///          (u = g^r AND v = h^r) OR (u = v^r AND v = h^r * y^(2^i))
    ///      where the former case represents a "no" ballot and the
    ///      latter case represents a "yes" ballot.
    /// @param pp The public parameters used for the vote.
    /// @param parametersHash The hash of `pp`.
    /// @param Z The time-lock puzzle encoding the ballot. 
    /// @param PoV The proof of ballot validity.
    function _verifyBallotValidity(
        PublicParameters memory pp,
        bytes32 parametersHash,
        Puzzle memory Z,
        ProofOfValidity memory PoV,
        uint256[4] memory yInvS
    )
        internal
        view
    {
        PoV.a_0 = PoV.a_0.normalize(pp.N);
        PoV.b_0 = PoV.b_0.normalize(pp.N);
        PoV.a_1 = PoV.a_1.normalize(pp.N);
        PoV.b_1 = PoV.b_1.normalize(pp.N);

        // Fiat-Shamir
        uint256 c = uint256(keccak256(abi.encode(
            PoV.a_0,
            PoV.b_0,
            PoV.a_1,
            PoV.b_1,
            parametersHash
        )));

        // c_0 + c_1 = c (mod 2^256)
        unchecked {
            if (PoV.c_0 + PoV.c_1 != c) {
                revert InvalidBid();
            }
        }

        // g^t_0 = a_0 * u^c_0 (mod N)
        uint256[4] memory lhs = pp.g
            .expMod(PoV.t_0, pp.N)
            .normalize(pp.N);
        uint256[4] memory rhs = Z.u
            .expMod(PoV.c_0, pp.N)
            .mulMod(PoV.a_0, pp.N)
            .normalize(pp.N);
        if (!lhs.eq(rhs)) {
            revert InvalidBid();
        }

        // h^t_0 = b_0 * v^c_0 (mod N)
        lhs = pp.h
            .expMod(PoV.t_0, pp.N)
            .normalize(pp.N);
        rhs = Z.v
            .expMod(PoV.c_0, pp.N)
            .mulMod(PoV.b_0, pp.N)
            .normalize(pp.N);
        if (!lhs.eq(rhs)) {
            revert InvalidBid();
        }

        // g^t_1 = a_1 * u^c_1 (mod N)
        lhs = pp.g
            .expMod(PoV.t_1, pp.N)
            .normalize(pp.N);
        rhs = Z.u
            .expMod(PoV.c_1, pp.N)
            .mulMod(PoV.a_1, pp.N)
            .normalize(pp.N);
        if (!lhs.eq(rhs)) {
            revert InvalidBid();
        }

        // h^t_1 = b_1 * (v * y^(-2^i))^c_1 (mod N)
        lhs = pp.h
            .expMod(PoV.t_1, pp.N)
            .normalize(pp.N);
        rhs = Z.v
            .mulMod(yInvS, pp.N)
            .expMod(PoV.c_1, pp.N)
            .mulMod(PoV.b_1, pp.N)
            .normalize(pp.N);
        if (!lhs.eq(rhs)) {
            revert InvalidBid();
        }
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

    // Homomorphically adds the bid value to the tally.
    function _updateTally(
        PublicParameters memory pp,
        Puzzle storage tally,
        Puzzle memory bidPuzzle
    )
        private
    {
        tally.u = tally.u.mulMod(bidPuzzle.u, pp.N).normalize(pp.N);
        tally.v = tally.v.mulMod(bidPuzzle.v, pp.N).normalize(pp.N);
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
        require(w.eq(rhs));
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
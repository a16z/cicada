// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8;

import './LibUint1024.sol';
import './LibPrime.sol';
import './LibSigmaProtocol.sol';


/// @dev Cicada auction base contract. Note that `_createAuction`, `_placeBid`,
///      and `_finalizeAuction` assume asset escrow/transfers are implemented by
///      the inheriting contract.
abstract contract CicadaAuction2 {
    using LibUint1024 for *;

    struct PublicParameters {
        uint256 T;
        uint256[4] N;
        uint256[4] g;
        uint256[4] h;
        uint256[4] hInv;
        uint256[4] y;
        uint256[4] yInv;
        uint256[4] yM;
    }

    struct Puzzle {
        uint256[4] u;
        uint256[4] v;
    }

    struct ProofOfBidValidity {
        uint256[4] vInv;
        LibSigmaProtocol.ProofOfPuzzleValidity PoPV;
        LibSigmaProtocol.ProofOfPositivity proofOfPositivity;
        LibSigmaProtocol.ProofOfPositivity proofOfUpperBound;
    }

    struct BidderInfo {
        uint32 id;
        bool hasBid;
    }

    struct Auction {
        bytes32 parametersHash;
        uint64 startTime;
        uint64 endTime;
        uint64 maxBid;
        bool isFinalized;
        Puzzle bids;
        mapping(address => BidderInfo) bidders;
    }
    
    error InvalidPuzzleSolution();
    error InvalidBid();
    error InvalidStartTime();
    error AuctionIsNotOngoing();
    error AuctionHasNotEnded();
    error AuctionAlreadyFinalized();
    error ParametersHashMismatch();

    uint256 public nextAuctionId = 1;
    mapping(uint256 => Auction) public auctions;

    uint256 private constant MAX_BITS = 100;

    function _createAuction(
        PublicParameters memory pp,
        uint64 startTime,
        uint64 bidPeriod,
        address[] memory bidders,
        uint64 maxBid
    )
        internal
    {
        require(bidders.length * LibPrime.bitLen(maxBid) <= MAX_BITS);

        pp.g = pp.g.normalize(pp.N);
        pp.h = pp.h.normalize(pp.N);
        // h * h^(-1) = 1 (mod N)
        if (!pp.h.mulMod(pp.hInv, pp.N).eq(1.toUint1024())) {
            revert("Invalid hInv");
        }
        pp.y = pp.y.normalize(pp.N);
        // y * y^(-1) = 1 (mod N)
        if (!pp.y.mulMod(pp.yInv, pp.N).eq(1.toUint1024())) {
            revert("Invalid yInv");
        }
        if (!pp.y.expMod(maxBid, pp.N).normalize(pp.N).eq(pp.yM)) {
            revert("invalid yM");
        }

        uint256 auctionId = nextAuctionId++;
        Auction storage newAuction = auctions[auctionId];
        newAuction.parametersHash = keccak256(abi.encode(pp));

        newAuction.bids = Puzzle(pp.g, pp.h);
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
        newAuction.maxBid = maxBid;
    }

    function _placeBid(
        uint256 auctionId,
        PublicParameters memory pp,
        Puzzle memory bid,
        ProofOfBidValidity memory validityProof
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

        _verifyBidValidity(
            pp, 
            parametersHash, 
            bid, 
            validityProof
        );
        
        uint256 b = LibPrime.bitLen(auction.maxBid);
        uint256 offset = 1 << (b * (bidderId - 1));
        bid.u = bid.u.expMod(offset, pp.N).normalize(pp.N);
        bid.v = bid.v.expMod(offset, pp.N).normalize(pp.N);
        
        _updateTally(pp, auction.bids, bid);

        auction.bidders[msg.sender].hasBid = true;
    }

    function _finalizeAuction(
        uint256 auctionId,
        PublicParameters memory pp,
        address winner,
        uint256 plaintextBids,
        uint256[4] memory w,
        LibSigmaProtocol.ProofOfExponentiation memory PoE
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

        _verifySolutionCorrectness(
            pp,
            parametersHash,
            auction.bids,
            plaintextBids,
            w,
            PoE
        );

        uint256 b = LibPrime.bitLen(auction.maxBid);
        uint256 bitMask = (1 << b) - 1;
        uint256 maxBid = 0;
        for (uint256 shift = 0; shift < 256; shift += b) {
            uint256 bid = (plaintextBids >> shift) & bitMask;
            maxBid = bid > maxBid ? bid : maxBid;
        }

        // Reverts if winner is not a registered bidder.
        uint256 winnerBid = (plaintextBids >> ((auction.bidders[winner].id - 1) * b)) & bitMask;
        // Provided winner must have the max bid 
        // (ties broken by whoever finalizes the auction, 
        // can be replaced with preferred tie-breaking logic)
        require(winnerBid == maxBid);

        auction.isFinalized = true;
    }

    function _verifyBidValidity(
        PublicParameters memory pp,
        bytes32 parametersHash,
        Puzzle memory Z,
        ProofOfBidValidity memory PoV
    )
        internal
        view
    {
        LibSigmaProtocol.verifyProofOfPuzzleValidity(
            pp.N, pp.g, pp.h, pp.y, 
            parametersHash, 
            Z.u, 
            Z.v, 
            PoV.PoPV
        );

        LibSigmaProtocol.verifyProofOfPositivity(
            pp.N, pp.h, pp.hInv, pp.y, 
            parametersHash, 
            Z.v,
            PoV.proofOfPositivity
        );

        if (!Z.v.mulMod(PoV.vInv, pp.N).eq(1.toUint1024())) {
            revert("Invalid vInv");
        }

        // y^M * v^(-1) = h^(-r) * y^(M - bid)
        // (M - bid) >= 0  <=>  bid <= M
        LibSigmaProtocol.verifyProofOfPositivity(
            pp.N, pp.hInv, pp.h, pp.y, 
            parametersHash, 
            pp.yM.mulMod(PoV.vInv, pp.N).normalize(pp.N),
            PoV.proofOfUpperBound
        );
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
        LibSigmaProtocol.ProofOfExponentiation memory PoE
    )
        internal
        view
    {
        LibSigmaProtocol.verifyExponentiation(
            pp.T, pp.N, 
            parametersHash, 
            Z.u, 
            w, 
            PoE
        );

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
}
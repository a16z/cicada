// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8;

import 'forge-std/Test.sol';
import '../src/CicadaSingleHTLPAuction.sol';
import '../src/LibUint1024.sol';
import '../src/LibSigmaProtocol.sol';


contract AuctionWrapper is CicadaSingleHTLPAuction {
    function createAuction(
        PublicParameters calldata pp,
        address[] memory bidders,
        uint64 maxBid
    )
        external
    {
        _createAuction(
            pp,
            0,
            0,
            bidders,
            maxBid
        );

        Auction storage auction = auctions[1];
        auction.bids.u = [
            uint256(1142338198383686886902819320732082578577431309363817754893980039034764883373),
            uint256(103983711865767732649246323293137192421209106113208046968364881815690124182674),
            uint256(44883659660729722820155170190224428585637013649597701055535705597723151166373),
            uint256(114216461688709016631004332444119613332436144287925535194536746687247115535465)
        ];
        auction.bids.v = [
            uint256(7149580790764333251881888377158112924477968466572189283037840536311537548785),
            uint256(93269476115446467837953665861115666057761127594526065638850036290112478922949),
            uint256(84364616879415947533115788162770283031561156519351272798815095998652043051155),
            uint256(68542479456994495398863416401623688763353930384629470485951643053089787218191)
        ];
    }

    function finalizeAuction(
        uint256 auctionId,
        PublicParameters calldata pp,
        address winner,
        uint256 plaintextBids,
        uint256[4] memory w,
        LibSigmaProtocol.ProofOfExponentiation memory proof
    )
        external
    {
        _finalizeAuction(
            auctionId,
            pp,
            winner,
            plaintextBids,
            w,
            proof
        );
    }
}


contract FinalizeSingleHTLPAuctionGeneratedTest is Test {
    using LibUint1024 for *;

    AuctionWrapper auction;

    function setUp() external {
        auction = new AuctionWrapper();
        address[] memory bidders = new address[](3);
        bidders[1] = address(0xc0ffee2c0de);
        auction.createAuction(
            _publicParameters(),
            bidders,
            100
        );
    }

    function _publicParameters() private pure returns (CicadaSingleHTLPAuction.PublicParameters memory pp) {
        pp.T = 4452;
        pp.N = [
            75453360789710896460315667585505962724075900172409899149212527020208811333103,
            67192980671578670578565147239473397365933862640850566537660689415038472073989,
            87683616783808132924828920530468275236558047145218739060675796767381727412107,
            21859837503244847595940229708542264784400219597186783119775830214115933504687
        ];
        pp.g = [
            31484368619405306455498604353943240416111110145832042297195190976655112376964,
            38359878711059391060735500500529460021858509176960929479667651629224281458333,
            115598099196790108900646995963611087597017935348396589955485411152085706743825,
            76849393427099187827869375195281279617798137231705174312201793846204840372062
        ];
        pp.h = [
            20292993263204533060680989895460189431932182329055947295856216338516526829210,            
            23645060619768362445799590317620081813906518417958751072908960565382086473985,            
            19848397330588085450876269589379742948669294521063686897248159431677716715652,            
            68988352044778728950659965911698219066661279907617167635649074595446575458146            
        ];
        pp.hInv = [
            34372708202269927741519087659722557030556848989389347528387140052697633813426,
            49462178480645078269361958690313862581421865236297111644139314543553354227752,
            63258266904441096184383065437387527949771687517726984579255328390385471754981,
            24455149690203268970470812719619184407719340391243709459139134492391970612075
        ];
        pp.y = [
            16789831493585314961537743958128776772753969873506138199944450561734950504528,
            104514624784351385435214362274893305646711481142782090647799725116783726116041,
            90958827183831692849034222321566059165488042790670097485676984937347104853408,
            498133750417154812974974905213409855565262288784837602539160675653351477736
        ];
        pp.yInv = [
            51723927953051458100702220470907915789431025556990490713556823771950036419804,
            12728702533820436694961908659262175826244260561828578035735905283078077317510,
            64800876725375665718192568711679334906843317250808938243136614488533235333080,
            70945284458180805847690199639709119692877883874363808993901143430740291223431
        ];
        pp.yM = [
            13983198831921767508693432832537508627447077407410264649517757091439554701166,
            37818149369443525893038267698869555016979557160483413836063763331195798253181,
            71605766612872505681793377328660101748403359668235439248128288211715481064352,
            58864791420460993659285657702133400215550058325056913135109415577636853546860
        ];
    }

    function testFinalizeSingleHTLPAuction()
        external
    {
        CicadaSingleHTLPAuction.PublicParameters memory pp = _publicParameters();

        uint256 plaintextBids = 792881;

        uint256[4] memory w = [
            uint256(3572819199484717208001134468953288730840140719734953884455788438280037023194),
            uint256(69622841275407666645261952177499684499492763165114293189871034558716366977386),
            uint256(98918488195845524999380145386426705977033063435481640522836468540955103079675),
            uint256(49436967036513525691148996117402662494102073612383741474954990537209410181302)
        ];

        LibSigmaProtocol.ProofOfExponentiation memory proof;
        proof.pi = [
            3916692567886471577239029453433673698247890493192346944225721390754102082999,            
            33635998207912669768658480532008976367135566318523714965343728931900172006044,            
            5598545084403389035181206649816462429968640716816065567972309547007367991070,            
            88438919432623080540945128397463894327642636206648118464302371870324315685570            
        ];
        proof.j = 225;
        proof.l = 97054004449810497102545363659541418055456287031458367011879389146999431590399;

        auction.finalizeAuction(
            1, 
            pp, 
            address(0xc0ffee2c0de),
            plaintextBids,
            w,
            proof
        );
    }
}
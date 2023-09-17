// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8;

import 'forge-std/Test.sol';
import '../src/CicadaAuction.sol';
import '../src/LibUint1024.sol';
import '../src/LibSigmaProtocol.sol';


contract AuctionWrapper is CicadaAuction {
    function createAuction(
        PublicParameters calldata pp,
        address[] memory bidders,
        uint256 numBidBits
    )
        external
    {
        _createAuction(
            pp,
            0,
            30 minutes,
            bidders,
            numBidBits
        );
    }

    function placeBid(
        uint256 auctionId,
        PublicParameters calldata pp,
        Puzzle[] calldata bid,
        ProofOfValidity[] calldata proofs
    )
        external
    {
        _placeBid(auctionId, pp, bid, proofs);
    }
}


contract VerifyBidGeneratedTest is Test {
    using LibUint1024 for *;

    AuctionWrapper auction;

    function setUp() external {
        auction = new AuctionWrapper();
        address[] memory bidders = new address[](3);
        bidders[1] = address(this);
        auction.createAuction(
            _publicParameters(),
            bidders,
            8
        );
    }

    function _publicParameters() private pure returns (CicadaAuction.PublicParameters memory pp) {
        pp.T = 90684;
        pp.N = [
            77172362864111114617917748173391518563926130646781395897952735037423669352854,
            96610448261158043896293629060087861863404094154536739522860101998449170256583,
            97942404613937553763725581857146462333053305725299043693607248412409052994209,
            15379587426505179214663355879126025467482381195924531218666088203234607799637
        ];
        pp.g = [
            31768423299267676226573863172076390898939632057458856354946906233306604658497,
            59418601664446797102659692260720422599022948472561203534791267032190223963413,
            49942800649643312515085086455378437538354974343079341277912464516007302923883,
            93187699793635620955763468227355387659576646357401993458370167886159587430873
        ];
        pp.h = [
            26843254846437587623637817394464570379669520473362294134057854189210159572473,
            39196789343809520903162294398348922644646328749049574051312231266181337563072,
            32079510925593890470462827008981888356693269959228190103868270348819701102274,
            100788162889534290445945321971847138171553390069927053303861719649137022743830
        ];
        pp.y = [
            34088446530395871200610203138684821552744237205191735552030375536657721003748,
            24603110130479336743109223604547272374101900665997340558899034012432982074669,
            13962553444138114580229548419106933067595412266135182314281976895309048910887,
            95268438723211289045074326041715066462064260965670325781784231521334392616965
        ];
        pp.yInv = [
            19460466021323094361790241396116745721078554668811020600818310600900957085270,
            101234089227087861360601061186537126155295377873598541328690603265774806735504,
            905164187177131436862655455916060240811668365609820664303500173891030781651,
            26105031284809723895646485463738681034419952965390212491566068094237393289453
        ];
    }

    function testVerifyBid()
        external
    {
        CicadaAuction.PublicParameters memory pp = _publicParameters();

        CicadaAuction.Puzzle[] memory bid = new CicadaAuction.Puzzle[](8);
        bid[0].u = [
            uint256(11910377678558977425643876474383974250160628869603311332329497221687335682755),
            uint256(29684572939374619655475587356313684172200989393589759444724269108735567902647),
            uint256(71185054181697249531546800686056297995748136341780204820896344071107738760710),
            uint256(46800089194487754523803940583761730457816255679291764943475516608212441161700)
        ];
        bid[0].v = [
            uint256(4171164039908963130969449768039429392925286591406196917373653190837954248734),
            uint256(92409103193803691205130845002401510550257240022856140395511081497852489244081),
            uint256(92902639161547646036788107629088140569841361271925684491096545399167764254457),
            uint256(39052822417045859342176779868752748285608802172266403092647375871480131210691)
        ];
        bid[1].u = [
            uint256(7129615116579196275405860460158066015092291259240660733203180716859784839231),
            uint256(67139731536057454654613517645969155089454256911560229891958316498433900205299),
            uint256(97442264516644652856704295186471573011747661502371065417790874212314153418917),
            uint256(53739028935773988939796186383678142993235593160407730039974705483743696963733)
        ];
        bid[1].v = [
            uint256(26112526764844478270266444747632597696460846081122004982311432420753387055246),
            uint256(100546494763643023035180735790648671173931206247859566599801547010581620895702),
            uint256(61499486739858819159273074168748608173747194343718052765518116641356408166595),
            uint256(28522647620445088305866066193329360386340487101283609592931273634727905530821)
        ];
        bid[2].u = [
            uint256(9699093586368411578485098879821303026996198645757194722800072063550320641420),
            uint256(32110365279728193973099938374633281824027617505316547804164625705161586821641),
            uint256(62461293212137948967652549946638285518126779503461550364302361933910682304207),
            uint256(58088060452146073269836536360717464078299840736170331756102608815218287280149)
        ];
        bid[2].v = [
            uint256(21722079524232967928684329968867551256798210720456068573362050261406183074254),
            uint256(21177213636187388443225053836640037706435390672558478214081574410658214200277),
            uint256(111456789394268146886031538554372413566433033605468562710692095196281960950009),
            uint256(71565417703929694389185781285599589164307835455058950810358686833903108970487)
        ];
        bid[3].u = [
            uint256(28679698308309597011788902404539368829020063562389742358655460450123574200797),
            uint256(25619487667046055828699132376261331770803627194057461948522587400219801762119),
            uint256(87309105579484056602816040236272682912811521772964398244493214303732803750285),
            uint256(72956221027214828837958029798909571252732325840352219552749980500789888408636)
        ];
        bid[3].v = [
            uint256(38192333041097830609796575486245251351391420945393384664769383649436557281829),
            uint256(17427114013118843288366556255465152045626370963801910587907957322628047049049),
            uint256(87259538943075496888410805444744313782790191644210494102701704931374778366195),
            uint256(77178053169767549333989340611514676466046344552058677229741315335822983195226)
        ];
        bid[4].u = [
            uint256(30123246642673367107820478323974298710051467317843537448598730421299153588008),
            uint256(99749561193531358629825001152688177680557999397672006228604611116169073151390),
            uint256(82344979241069766022034061319989178670489684715442737825261679103676884842835),
            uint256(53202198121182400053925388519661757236915114319105415787752877712406761411696)
        ];
        bid[4].v = [
            uint256(2972430475925050787880942600810430997454868959660656878259012445580495522875),
            uint256(67899961135560251764614281472831716619067118463512130914990359764582416046691),
            uint256(9220704431828609083141752412087016652356808964106694494824288713733983006667),
            uint256(33328167682951760465909565335280940014386194427961856074676352583725692938984)
        ];
        bid[5].u = [
            uint256(29113213457935748863025413059708969569683289538171970157715029733145240322784),
            uint256(17703747244404179973397293759032357820849402119057523730902864240794622845509),
            uint256(16425489868081317314557205072898118700785438450752617639626191557858232290878),
            uint256(11765910077087998485025410230765215879617704683320580221382869101610963320523)
        ];
        bid[5].v = [
            uint256(24782299833278312585415986571686438824580629674336806641460989946660315039662),
            uint256(21309267434560748999340307648827124631636581622351818072459691288639731281181),
            uint256(101933712506382231441858063335123058366746949504489002597220662998342067246395),
            uint256(12363604228691536676375691604373419850996884908860237295232355688391201561126)
        ];
        bid[6].u = [
            uint256(33340856425957807696895055611890312510368482361878130427705858377409579157232),
            uint256(58181406951832874676601885951334259263351189086414700767078660992488138910246),
            uint256(113988126109428991120422162049714469541165587299419258314324322966224294144506),
            uint256(35536058026286188829514229506826177876898412966650069556921029314609073294157)
        ];
        bid[6].v = [
            uint256(20935558297201185106211313200890552955498987264097772815326883881557338250366),
            uint256(16391977597619551477315188998807767091235793523751963822897519944880830579049),
            uint256(90678879687470953618534334852600162331179166967458944543965005562344438068667),
            uint256(73740458241382974486770104483283846893217757012978243513325386831791591001631)
        ];
        bid[7].u = [
            uint256(4465947461330216826802534208768215393776765471123841354533732787860629302263),
            uint256(79763538022647233951755378438738483105504679111224417959644216308327288460306),
            uint256(23498067065754740773533123367578798230035865708095692478688984292693966686253),
            uint256(33296420813130078304890669777661098726312474772440151330539460638710240616716)
        ];
        bid[7].v = [
            uint256(8279799807958907029076815660444419641490585809852600867807280532022258799624),
            uint256(63779241739582212850723142462256587782922054499802329488443294375853404271413),
            uint256(95197651822305506341000204221923131881910746138450211087770817441885668068610),
            uint256(43958629027675174378090992800915151118309810195805071087270178006836644187984)
        ];

        CicadaAuction.ProofOfValidity[] memory proofs = new CicadaAuction.ProofOfValidity[](8);
        proofs[0].a_0 = [
            22303265882331957970783406330844350789343723263944107185995867264428550931278,
            85769457981897557116155968131667426751991333851261582630767836468474034888362,
            23971884679599418552951790066093310384803943417824785630628319125769587426389,
            17360819856964355592086383749873001817608041802632137854047857846996003467764
        ];
        proofs[0].b_0 = [
            24585376298301243025638805407394607987091835665227698610238692904676637585869,
            66451475081852091624497356019275775880745069433895729567734452133861949964029,
            36899667969441654859929203714122898777434668374379902515408191575432496520320,
            94203482897108706980802042941014560720794910161793269729366353018241158623187
        ];
        proofs[0].t_0 = [
            0,
            0,
            2361324394069105748031267433064182343050993450142854232472146557664485037356,
            8412378213218520169801054141378838921726536872440033838987070094550213899068
        ];
        proofs[0].c_0 = 70562909424366213106803915965063002708584915383303909957811670256434048701565;

        proofs[0].a_1 = [
            12928261387546991025174106105853073571636600487333039944907208759518884855910,
            64736821811213633393372719719678828184883579173301775745179529174144465565942,
            755082387585662052935730803656032974626719780212978567972506245914459755782,
            38459653491401682500919923861765376420291542782226235513561256709485382218906
        ];
        proofs[0].b_1 = [
            7696245560098791415481540213046599058558344887064502676136856991789031049120,
            4359019707019724817236796488712317816408412824226245083236189289555537130342,
            81499384234000950043452495014776941499682807323244701183636439705593653998390,
            16726875930130171223312248596835497327386961794194845045917834732809389348015
        ];
        proofs[0].t_1 = [
            0,
            0,
            3596779148695380337135091945944289890713998560501858234757264134388278181675,
            69251771572125742493459907752550997684688882809105303584095223523842190237577
        ];
        proofs[0].c_1 = 107481717432091854161480928529791399750104816055830967234527971747142102161085;
        proofs[1].a_0 = [
            13152511320443216268910041618356735781186104839518937190844521402650575344353,
            51493639589807931717219542358430069841167112804942599579520581895792150440536,
            25570603216361703331813545524202461718011418381371642069691416326209521716954,
            66997846951793664838187874288237518718068484875781923693454818921016140372149
        ];
        proofs[1].b_0 = [
            8515855022123413624965773742689975950182562162813297871576686632446499296638,
            93522920729694210948645141719818327512611296912546627325034017895088715060935,
            27154372950329389547315524578572937853950050279394562946758442053255877923530,
            92411696054137079884027519729111031148300998828556459130649418335507346742248
        ];
        proofs[1].t_0 = [
            0,
            0,
            6279408871447152853881712966297728012658992438889642519613126518285970380213,
            77667938008279262820274621578113376198597810345321048882552305633225590079896
        ];
        proofs[1].c_0 = 112218961454112032198515462420201974697956479803717937894052095835578605686067;

        proofs[1].a_1 = [
            15674856069478708708597812977062008756182452128768027960886817501966516720249,
            10084701545593931808076413335417459606126631309820123070382960209092951359922,
            29819009549862404403112855782733379371791624637564223987962117945925330462923,
            96556026188963573857072730850317199722973849489922044315052908174144129305922
        ];
        proofs[1].b_1 = [
            28614139485320196547833595266931508379687496433321335535762216482630725280092,
            96156176980643729170225285734117644712223595623445764306575742436008510133900,
            66210022368088384834962248375671438720956095355697810978908626395172916669479,
            65080406928257893955943386701969038830626537995622125259210187749547965742081
        ];
        proofs[1].t_1 = [
            0,
            0,
            6077395039740207988428161902297799509166329779544850161115529361021352438018,
            95120834857034964537669880274783308038120592239915627053347832359339804832328
        ];
        proofs[1].c_1 = 108608783671837019765140935701839725045017907482499854824723702383343326985632;
        proofs[2].a_0 = [
            15569553209455567898776757853177006276218777843596062959011997223169103459940,
            65795426559977476388174945882647351393727511591895396981633085221284059230040,
            80023559410559150531918755144079890894131543126776734464737063965617908285067,
            23102190766521417074772072647814656229479642700224750215744379194577531275935
        ];
        proofs[2].b_0 = [
            20770060371154902149882700580570036905261227762469378208616662954423174470152,
            14547511389844016180545657257989368005772874599902243157912280084806668523035,
            67649938248592568398501140291596552145711602287286367688189090456443724085847,
            37673620658692813712041600969893227131546817631878397335867937220065272880623
        ];
        proofs[2].t_0 = [
            0,
            0,
            54685041825828401494653030865087023213396502710127436233144307460332819636461,
            2573970786882388188792544030666709877392283843184324533358806502377657614260
        ];
        proofs[2].c_0 = 109223805674470527058134076805730512569431987913549852367443642287370190757496;

        proofs[2].a_1 = [
            15954979672943723049227577435551491469791945562064029639510557132423531603601,
            77642766023014276388926575919044723795562243135387390668458734178389459448797,
            99141597128136339801217643122033687384621821595736903160032234081246208449031,
            68471265672815159953412228752270978810631108564655328225472304470755446246863
        ];
        proofs[2].b_1 = [
            26315417222309495669801791448784774131312313781802813059542600052738287462330,
            20733721028681641486284526587154445351719505749120291276789987247561343053246,
            83170078080667964715554709267380947797662111434035464420929837278130801233630,
            108773071363891834617976174292202955675368938738016319426807094629931652896753
        ];
        proofs[2].t_1 = [
            0,
            0,
            32436726423263797167465648843004974250843860068893626784277878029550626524174,
            65080406250648303707279625339325491190162088210301513612129790718776076308604
        ];
        proofs[2].c_1 = 64786687278296856702515619551648094954146796858263659769627951671692084268273;
        proofs[3].a_0 = [
            26306105096420461323145607298463059612452671376839704675286639208358167008173,
            111519574412223105155993595646690005028430154854780224503645309249291910481407,
            91169628572884287040214193635477414526800927998471066134845004454817054478082,
            33276443993193219279593179209865487855052233915704901826650189869877889471487
        ];
        proofs[3].b_0 = [
            6303018545112656856442855812806619046629133798972436177736060852385377639403,
            97578290420069374005963585039773334908621649075396480243031406470361802198468,
            32608347286660927173973744823338801643579318867499610951613690241786856727740,
            38481197984143851254025823760726024102257500261558022933028274023723127503339
        ];
        proofs[3].t_0 = [
            0,
            0,
            8771538017613952573924988472468663826570291237261712747193375982288934515042,
            45376543312140467602308784984565718882811308446179698784480045490147476960996
        ];
        proofs[3].c_0 = 22627734594180881109557670430089401254924907753301886522665379302593819879597;

        proofs[3].a_1 = [
            23194555683947803787077075359255214375376879436783276419974615215700260239855,
            68634380579547997119278820586184186183162945384142881975485492131247843331080,
            22661673027132167357405850340177304242552062419960078356030081140622649231174,
            21980934483120299887490368788370181236718798890749843057259388792494705366652
        ];
        proofs[3].b_1 = [
            11253353894669968586955260123986942450275441053034583267589178025160709021069,
            16128435461503197678790198648949829388534449493912931380220169499915264210897,
            28384917623856028682365924766851843116296611797375950080784773208041342906825,
            49258271643594420438814906489603372329204204909262455626868370290651531258679
        ];
        proofs[3].t_1 = [
            0,
            0,
            8269825026511473942057883964663154652009835170725351204600062962386279998307,
            61793494295702222199375907294564536050387980340054308737848744434613430589687
        ];
        proofs[3].c_1 = 21333477146704448693525716499268433681590209439734545126960181861695943210465;
        proofs[4].a_0 = [
            18254657457465712729483509311799648575017594042691315542088232962594921051064,
            15096386706677086581597800983132294734745134889125178916712651568167912078538,
            83547574685882870948903862242849403246377080045556455998479202086802415666675,
            114514716039758940373159010039131300811235441499019523070408932495331229839757
        ];
        proofs[4].b_0 = [
            19808516801300456026538512217638852804151150935941227657293387885851973069413,
            93905408501364379770441590065533614664619039865153822270944998191622883746833,
            106538050990774565318932467570771736224275357313647021989660974433696087551974,
            48343413472514345908051715941879601440682499621967243779386950148845240990686
        ];
        proofs[4].t_0 = [
            0,
            0,
            32286923526590608945791168574046464781939884274521683815889728164813062167087,
            112155721955200556136071571121473042347801666905529813944233213605255618249644
        ];
        proofs[4].c_0 = 34196350997365781475383998914934619794250173773922303363058408496115711471900;

        proofs[4].a_1 = [
            3479755773180863156841816057161840696522437459245446050091292402360704540295,
            47698567142408892108517404094141598157528708233607717973342089645195275687202,
            13286462645454468660708023375889221358053240566618628214879601386014624712485,
            93781507997296756319073662289135091880977671588478120507499124423021990257181
        ];
        proofs[4].b_1 = [
            31098858117168907114825760016261148140783631975081700088735130197602400482133,
            105884787660041412987599942149831085743749404652962579108002193716631893957427,
            95656996184006827552717212071338476137041772748792093709390487029694012741125,
            37073757062143419052805781008577183717162287223550943449827128843663412105161
        ];
        proofs[4].t_1 = [
            0,
            0,
            89912373091093662508455585769187130508282831917705594617032106840770630695177,
            36689076431335268706946315773953069020336045076258780285330105790251421360638
        ];
        proofs[4].c_1 = 95229731835457424705600558616355652835073224014368233839720303872669449307405;
        proofs[5].a_0 = [
            7578702111176374398418648353042713395609454520571766044899991399432010485722,
            84809249641874352877700956987833283188139109960727094927777241859396199218429,
            61104865290400272060462488329040731502261900419737584307559936049867486824048,
            40281970872965175224990452465943991970514697074987701302586411358513266317779
        ];
        proofs[5].b_0 = [
            4692382173155130424481406620186298251668920324687448474088967551925983383803,
            26172214813448116187680210787211756474953544815753268628837053947966417040939,
            61304235370386751966592245456993829830262366117749108539144054792238473515743,
            30408123844026657706768193025682822644885190018301073223600335227234172645065
        ];
        proofs[5].t_0 = [
            0,
            0,
            18632044886427873566460042590344994217908234383499422437267437571315101820434,
            2137500546273307149000946039299147724142906316653931252546734543862150047211
        ];
        proofs[5].c_0 = 29107623848394238828825029071983874637180925887476793457901053020768402833031;

        proofs[5].a_1 = [
            6390285537977576559895481588536284057491942803157296125395967161234053729146,
            99186787138534147188516476352741194766330114893070435194365213911277799541344,
            53568369220657156488697117208182725839112968946231089431237542359861338497225,
            102967880157330193914695030780417934424844583970052426670502515607003497225471
        ];
        proofs[5].b_1 = [
            1922920746994501554884151534421263668414218265659299581813239405444825049028,
            50213714390497510693099113955642157443403527322519885854245894206618767062907,
            33708581920410753161259741585341426596800937431990546154430888242396628160103,
            39000162628013568869733826950083393447531155970440468208224334939072324318479
        ];
        proofs[5].t_1 = [
            0,
            0,
            54017291683622328457412183468362984774966375518467755284897223569755242415819,
            110981921297342509106059935906624395043307906934398629178427610653539892620203
        ];
        proofs[5].c_1 = 84387678175957664758466161304495230546302581888300628186506335123092583154906;
        proofs[6].a_0 = [
            17421943368568659575554234967760837000883040872515840677759304660256775531347,
            44444559111901997627335524494805101847588038225043225374203293221372667778921,
            28217552403116706177358215440533414400827844920780734524071917893749528632944,
            56981490976541341052412249661061112972278140033918557563569772001273848324545
        ];
        proofs[6].b_0 = [
            77713973853313551468914073700330706183372566353028500943594189899899379436,
            86147692089449485126647711865157037476656676470756320164210458648227492046540,
            24319832023332323924336023352475935164497652222259627853449277588566067739914,
            2025447626132036629589491835287353030076402245023432389423326931603770773692
        ];
        proofs[6].t_0 = [
            0,
            0,
            8975731881566043012261772544637211424213045801302769772277640965325442937703,
            100503864975602898253322587260683317925405558859863610755221708836381010953663
        ];
        proofs[6].c_0 = 32711297751872073893072570098461634157110798245121145806050091411475433471373;

        proofs[6].a_1 = [
            12681251467999100602837295854030123625420990576554316269210368434034142439396,
            99760730916795907929168319035756547535413105396276319618913888556080714252944,
            20455354797919251271207493762528621249873127710843768627840645738770378290916,
            72187772102265471801311132224530297680888375810067656664667393373872661390298
        ];
        proofs[6].b_1 = [
            20222927673629511033580349045961132354442504525419830850003244378196223471847,
            40892264974599578573780493785462402230982848177685198393079377014179058443750,
            91371515035569608253953982502711274051168260770204315459463349288759527248370,
            80685416884413672991894366507641710288127511028296912450597838904566216977204
        ];
        proofs[6].t_1 = [
            0,
            0,
            29090102495588037489313038298291094605357434704686130075735642417891135844565,
            52864201824742630087303419577027605988807166119135257981043550808251638358983
        ];
        proofs[6].c_1 = 106016424835501090723452503691921307000154602867986594398979372353761355523904;
        proofs[7].a_0 = [
            38234162283170466025131811912600048338205283377666083603695923435227372404231,
            85222628721736404132611172128250043084015999851192712243572810554227288558926,
            50579401633042923201050269931030155933973531339801452982301316467582464766952,
            16700578931846945629661285128889217805208210204026409932466995409102546872212
        ];
        proofs[7].b_0 = [
            29912064766005253239774858138564513898534482691910936572562957019537337521407,
            59708226238703351962598842430659597322467315929830753305048083397618074992501,
            99176691428062379423310895608466347523709478243847123990995751770621175424203,
            3784758193517885129468882860641120714961635439994069978858262964959885777176
        ];
        proofs[7].t_0 = [
            0,
            0,
            20499523567179229646681299440521757823098302016450393151625399950079605744169,
            30819549133143149416187723710096021170377862149072568444608136758064379903969
        ];
        proofs[7].c_0 = 79907743826784779786972289271612726851280098021093719512498107668727038875245;

        proofs[7].a_1 = [
            37940617235321979261846916075534399679520963850417440772063731378699004313985,
            21116989307308735524016828401863644032351867600501936222240844612138541345990,
            59132836953713808240798904085554796662395486200000631153831172061499345941344,
            105196287142272960693284492008242995173781464916982827972152315345423880227991
        ];
        proofs[7].b_1 = [
            20125119490246571872403951959323940146172450392367084992082842280333154103552,
            108769278567255990692514395263021896952230351361615411216339935712831758881711,
            76252758334537264665123396632791566658243822749426969002379647352281296706855,
            64160896266903485046686690643684781083519864982924969241929446641829295991787
        ];
        proofs[7].t_1 = [
            0,
            0,
            4830893294459262254576689123072979668574282015270818606005166488673898742976,
            115289430033304407653158393455255249030909046789925701085576808210045882510701
        ];
        proofs[7].c_1 = 18830963683772135828510009497367659373353689926308236117140151797185213267244;

        auction.placeBid(1, pp, bid, proofs);
    }
}
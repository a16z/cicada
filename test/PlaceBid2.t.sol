// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8;

import 'forge-std/Test.sol';
import '../src/CicadaAuction2.sol';
import '../src/LibUint1024.sol';
import '../src/LibSigmaProtocol.sol';


contract AuctionWrapper is CicadaAuction2 {
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
            30 minutes,
            bidders,
            maxBid
        );
    }

    function placeBid(
        uint256 auctionId,
        PublicParameters calldata pp,
        Puzzle calldata bid,
        ProofOfBidValidity calldata proof
    )
        external
    {
        _placeBid(auctionId, pp, bid, proof);
    }
}


contract PlaceBid2GeneratedTest is Test {
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

    function _publicParameters() private pure returns (CicadaAuction2.PublicParameters memory pp) {
        pp.T = 4452;
        pp.N = [
            77172362864111114617917748173391518563926130646781395897952735037423669352854,
            96610448261158043896293629060087861863404094154536739522860101998449170256583,
            97942404613937553763725581857146462333053305725299043693607248412409052994209,
            15379587426505179214663355879126025467482381195924531218666088203234607799637
        ];
        pp.g = [
            31484368619405306455498604353943240416111110145832042297195190976655112376964,
            38359878711059391060735500500529460021858509176960929479667651629224281458333,
            115598099196790108900646995963611087597017935348396589955485411152085706743825,
            76849393427099187827869375195281279617798137231705174312201793846204840372062
        ];
        pp.h = [
            590527877384768893130631790812773015759685958225295452510747165528588670397,            
            72291402931824529649172306290000012059922418408720348768826120867848108629147,            
            76779887900233739716514715466947754001069682222045324277428108670980920990655,            
            3980807396130520052695088382486288301695223925536648410058494555600925977185            
        ];
        pp.hInv = [
            42407823819184292453896611350082173026176257559250642982333679475039555806737,
            39224113744420543542192821524693940733014220431593754963727911970990527963868,
            108933500552621971691729381114469310301707869809053437940432682163102321476537,
            62092157882647333859918122054546300309697127492380448038513955100001449217384
        ];
        pp.y = [
            18508833567985533119139824546014332612604200347877634948684658578949808524280,
            18140003136614563329371859086819862290911727990827699593541553692281294658699,
            101217615013961113687930883648244246261983301370750402118608436582374430435509,
            109809972910993681855269086084485078391917408553163149740887002672685155412622
        ];
        pp.yInv = [
            65494458080485439230280023104139816637631778984207086887172766160613738541916,
            70146703749005654356246409328179969934193414761275440166536019867079050387171,
            49545265425546519166831257618437116015518406814481842553001168641458770573961,
            94723086202484756366624739306038060945185541272244089500648596578548698536022
        ];
        pp.yM = [
            3113754292959738346789874052266681723878456329677813947725452065856988496173,
            96440609492966481459530338229587720302589804646762440148727260706235382066268,
            18269575182834415871927297541829920786203719873310237402090393524944451248599,
            82020565876742803963106506531360329552720742544977889223104244569758784501360
        ];
    }

    function testVerifyBid()
        external
    {
        CicadaAuction2.PublicParameters memory pp = _publicParameters();

        CicadaAuction2.Puzzle memory bid;
        bid.u = [
            uint256(3645079519808016101769028864987868630190370736396368530725398410356918760351),
            uint256(30734240580332104532985672720391798742376246884905696914170112085731002146005),
            uint256(32233499457725379883517615453672330395014002456932354024963919843355675947084),
            uint256(37346718341639731819075653846542258967081312493756311918229196508096340641149)
        ];
        bid.v = [
            uint256(5761422593276007596624607107484500290598401967863244019332098364850987868601),
            uint256(65251758616132038806160402196597433875445539086576994500738386374381094698173),
            uint256(113901121113135638292378407454997200609298585426416258783039726333133926266185),
            uint256(99987162437223303796345729911464202528699584647781628762078985141397200152332)
        ];

        CicadaAuction2.ProofOfBidValidity memory proof;
        proof.vInv = [
            uint256(45723799938320742768426410113547901485842046178839498157849198251574427024345),            
            uint256(40072376340333579254585519734166533718860370246097963374463592702124707655379),            
            uint256(792844815266746099853137388252108333790678851431940870098237880985174128582),            
            uint256(16565937906588426968267536986855260047817807352477609124864676097368876668998)            
        ];

        proof.PoPV.a = [
            uint256(31672166495216495159965985635297845322075290349104559905440267775898786451811),            
            uint256(23319726135491289468462964219975573133030720215215136944086503375541329394616),            
            uint256(113678239095289800793830048372034882728416277052457086707662891045975693969459),            
            uint256(53008976597044849230434213549445904728850184264451535517732326974640271185535)            
        ];
        proof.PoPV.b = [
            uint256(22571783825957097176587760111565886409268510380265903775369637933616993162459),            
            uint256(95659844220265931366341191532670613654256605431880330746394284419284744602205),            
            uint256(13249618208655637837064573084049906647733346416628361641876616671911123316761),            
            uint256(114508910811573140185404002906779720063730184279420066805407163357157966566172)            
        ];
        proof.PoPV.alpha = [
            uint256(0),            
            uint256(0),            
            uint256(10497279894574326290961254826173850438328569962840630806706788239958365690063),            
            uint256(20389198952010492497468465598903778835108932210449502394380485021958814476148)            
        ];
        proof.PoPV.beta = [
            uint256(0),            
            uint256(0),            
            uint256(4),            
            uint256(55988072863076048519471047754062643767302140895718524236323801955734073758098)            
        ];
        
        proof.proofOfPositivity.squareDecomposition[0] = [
            uint256(31391809950362719363117924420814818127145048070898970436592496121020871457845),            
            uint256(24396298215225510335425926121186717854134080853957651011029494122407493461986),            
            uint256(50262789308330711837280645356236938619348195442383033437566240723821321021212),            
            uint256(20036240010351724690518986657459236473440685389969953921785930731418795838579)            
        ];
        proof.proofOfPositivity.squareDecomposition[1] = [
            uint256(10716593213056836419566637025188485396338559683878857092890540373312464324185),            
            uint256(30522627426930882876092070903961379748148475572933193088463022525447868466550),            
            uint256(40507597695460164732864591397155201356205182131023147380317443008041431907231),            
            uint256(43991380534943533395407824419363819020236595200825590279500902714400708828425)            
        ];
        proof.proofOfPositivity.squareDecomposition[2] = [
            uint256(16208256838193537783442287554078349214218093273248203491661581494688086177963),            
            uint256(64876138239410502137010601067605215614504723487345306777287625823368564765879),            
            uint256(108723308015919905325168161041013871027115843702624413259409795790633998598769),            
            uint256(15560951871803945458829172532562491146817988465376649484846826271200430096214)            
        ];

        proof.proofOfPositivity.PoKSqS[0].squareRoot = [
            uint256(38095791345276146299788923898135392611114556903770958427112513512201623143627),            
            uint256(32586508169629096297516754417882698106763890394614171909602514524588298085126),            
            uint256(9359680215584147265143981451612317703219780520703155323661675182144378861349),            
            uint256(87547185187825025955710958012791116904395195469416925623667312162753611958584)            
        ];
        proof.proofOfPositivity.PoKSqS[0].A1 = [
            uint256(37475748680655041553015462131835329097377043812671512369165543040403839138556),            
            uint256(87403509819514509862012395291763954509602823482576573226557820447827794757750),            
            uint256(62252558843072696013272817421025977739751388344255288357357855830236406249806),            
            uint256(6602649182684247425889854706464497398578157733535841668727260362820852723074)            
        ];
        proof.proofOfPositivity.PoKSqS[0].A2 = [
            uint256(24656697161190048978386408970381091326846977658118743708571278401867409248574),            
            uint256(71544286361791723665389583322112710455098965801258647648798144211849205715949),            
            uint256(61569212376406679969063676412047462541082485192000517395509775710123136231844),            
            uint256(8601215077238469297307093887693979308041459756888520877447313395577400516097)            
        ];
        proof.proofOfPositivity.PoKSqS[0].x = [
            uint256(0),            
            uint256(0),            
            uint256(1),            
            uint256(2647743492068407119623027162421277893078091149554158521336856882401761807670)            
        ];
        proof.proofOfPositivity.PoKSqS[0].w1 = [
            uint256(0),            
            uint256(0),            
            uint256(27830549018626267478675211924873281556365791663041964819542840242222422329639),            
            uint256(27213576810779353373325655530538048109189906967684297241045184649916908213296)            
        ];
        proof.proofOfPositivity.PoKSqS[0].w2 = [
            uint256(0),            
            uint256(0),            
            uint256(20886229687388987414243085882491266293753877712599602990284850742001448172793),            
            uint256(113554061469011476464311667218769034952373064910566883809281402345567571037747)            
        ];
        proof.proofOfPositivity.PoKSqS[0].w2IsNegative = false;
        proof.proofOfPositivity.PoKSqS[1].squareRoot = [
            uint256(17239265040941611364732794525332177679715712789996205283689273216785873778207),            
            uint256(46956096978378778199943684507122484711988695484844767630508531939077449925458),            
            uint256(75476063567284589105598436691622656743178915222436953192285146427787278664605),            
            uint256(31643735854516067704660674622443306777547262887611570990694722624890742735582)            
        ];
        proof.proofOfPositivity.PoKSqS[1].A1 = [
            uint256(38488466715763833014164241447359488721083147758766229771816157438531810209626),            
            uint256(89681233679187615645801181562578398609594192656994865278862425846398514724128),            
            uint256(34439276782176823568439064715658812909028369741131390662004915820583403699813),            
            uint256(17404646433959863807456338913141790453588892553713885527955503702485012222610)            
        ];
        proof.proofOfPositivity.PoKSqS[1].A2 = [
            uint256(4337436936324917665556884397414672374096489332476196948800923525421794250348),            
            uint256(108405529057352040964534553690796392184171043075312224657194977648958532978826),            
            uint256(76580828997425792425579918078687470658044275048688365373363050253982179440403),            
            uint256(68619951891109135005110790493884881845438229008007543432338003285203809621015)            
        ];
        proof.proofOfPositivity.PoKSqS[1].x = [
            uint256(0),            
            uint256(0),            
            uint256(1),            
            uint256(96189640856309362632503507471630996034171646375364653346502415798850227952561)            
        ];
        proof.proofOfPositivity.PoKSqS[1].w1 = [
            uint256(0),            
            uint256(0),            
            uint256(23471810241107722714630830207267459239331860169543319012020645717145968758741),            
            uint256(18137974412284676363780369905912895295696729921397661663132511718137308199359)            
        ];
        proof.proofOfPositivity.PoKSqS[1].w2 = [
            uint256(0),            
            uint256(0),            
            uint256(3079373288974984768869382557072184549862291311094386139107715481389944868126),            
            uint256(73510874772519922960278800511774926447299695206026393391970197601472135834209)            
        ];
        proof.proofOfPositivity.PoKSqS[1].w2IsNegative = false;
        proof.proofOfPositivity.PoKSqS[2].squareRoot = [
            uint256(34761922150474218175128729624794744733676923249573536351125736372160083830812),            
            uint256(67588297833527968860585642622038527593135292308247459250778802393391306004210),            
            uint256(9534264450659022957520581681160102073549263383728308145004057761662642872065),            
            uint256(45995748077562968250491399528548782811447018799392452996004548493282883102142)            
        ];
        proof.proofOfPositivity.PoKSqS[2].A1 = [
            uint256(23789196999337858618419419535268748659079495881404924573762345671955535081393),            
            uint256(61737184202679289295693164657822151379687619659003098828305151386548451083415),            
            uint256(37003630245687178067416201164782622263663687253910120226534156960340928900784),            
            uint256(28213895212919382904794668947595100857430201822389275484430577152834785578525)            
        ];
        proof.proofOfPositivity.PoKSqS[2].A2 = [
            uint256(34069784650690127958058268182855550020234193268546286464024179986755307466804),            
            uint256(39782190709956041976926319001682024988481536055756817694064198051521547544187),            
            uint256(39587194707018856660621484099406514516788723578632108926496093756159405245985),            
            uint256(74348115749202099263521891909940167714340485006652565793612441652691670276073)            
        ];
        proof.proofOfPositivity.PoKSqS[2].x = [
            uint256(0),            
            uint256(0),            
            uint256(2),            
            uint256(17501930679083926956549818659606820416498701431246887409195859373377816243041)            
        ];
        proof.proofOfPositivity.PoKSqS[2].w1 = [
            uint256(0),            
            uint256(0),            
            uint256(6648368455948022171596673192733026907736917185177585352133277242042865863367),            
            uint256(93307882467038202028534435810451020070409141074091501463162543634618443251514)            
        ];
        proof.proofOfPositivity.PoKSqS[2].w2 = [
            uint256(0),            
            uint256(0),            
            uint256(61076651904105137573326585429855148882687548028288290344198404793402933035065),            
            uint256(106274547768159690418313178688342987781972844888176876406694231169880570329360)            
        ];
        proof.proofOfPositivity.PoKSqS[2].w2IsNegative = true;

        proof.proofOfPositivity.PoKSEq.A1 = [
            uint256(6372361391849336239811406942546395161738008468620954609260642293094575892216),
            uint256(43869034194005589195175078488475695748794147510502773773498043692496050121918),
            uint256(8557205919986627748925114014340300544763866312649588205805863387254167332078),
            uint256(39589125123782623692447961043601407823939550249011710728783509486354493190086)
        ];
        proof.proofOfPositivity.PoKSEq.A2 = [
            uint256(22090261975653084164364730268321955800404587115951342678643176568164316207072),
            uint256(3931978250070712929190872562763825735432749639149969814730006754797007814565),
            uint256(115231142988146928352120263274218840925161350902079579765893258620988664560305),
            uint256(90591765144190976383599152084358469748641328220880700228768632987872517904091)
        ];
        proof.proofOfPositivity.PoKSEq.x = [
            uint256(0),
            uint256(0),
            uint256(100),
            uint256(25976938272333964266125011478574296500091784976748898452625470238690723661706)
        ];
        proof.proofOfPositivity.PoKSEq.w1 = [
            uint256(0),
            uint256(1),
            uint256(25673436879074758676654853198321791275973544491451243272105417029722821377986),
            uint256(66779181507567824414366422880009393072325557554228264854836748260933592836350)
        ];
        proof.proofOfPositivity.PoKSEq.w2 = [
            uint256(0),
            uint256(2),
            uint256(10093687159760306906696909348799612715747817984630398498927125036408168122561),
            uint256(67951419247975247390975333674727272012170345786528594107515358250071799357625)
        ];

        proof.proofOfUpperBound.squareDecomposition[0] = [
            uint256(37669161769395536984075745472198902046499525773356647843923548809701780419045),            
            uint256(26650184637695089771229923059601705099529494929005802689889080405566850853557),            
            uint256(97914022803649339955103963659276254133875209166424996007958839527989343118887),            
            uint256(101246627940680582594944983668835179740151070686748137296094251936363954151554)            
        ];
        proof.proofOfUpperBound.squareDecomposition[1] = [
            uint256(1002488871584380038538153495277942735898047255328190838232819503342780310652),            
            uint256(89547503941750669411159979617514533185137357780675048217108709315624927602630),            
            uint256(71592963347244649344282572943578539703104563146154347189148544248683041118957),            
            uint256(46042626313038211071389199030970424537328177826722794174155803971478421772109)            
        ];
        proof.proofOfUpperBound.squareDecomposition[2] = [
            uint256(16565775162620851936276030256718103122330268581158606335973935052908454032320),            
            uint256(57678569636037683872874723953757561294066852842171060420829636014484825277253),            
            uint256(23368293023812552552905218410460794685654980135689076052950319081782215281725),            
            uint256(90697580167066806881724180601334621517871641964518401686746492370910762931029)            
        ];

        proof.proofOfUpperBound.PoKSqS[0].squareRoot = [
            uint256(26015627909136866082446568069653659996626084091628570448240676607396240833586),            
            uint256(109806742133206720971966467318373029682288482508948514254100457262500542937726),            
            uint256(103426813519165211569405209108606515887018066787530473459756952674928665270320),            
            uint256(30026504349547210911721657487125569995335565922484970008283665186983340518535)            
        ];
        proof.proofOfUpperBound.PoKSqS[0].A1 = [
            uint256(21749444085839429146311030234690217348025149706112593545726730110584502248161),            
            uint256(48903145069070278225888876541158931752426963009176492624868077358363998899143),            
            uint256(70007911346170002269787515803754077574188551930760896476139125678874742873428),            
            uint256(6278818835430973006100996133103352137543160941705118505502176639887439908297)            
        ];
        proof.proofOfUpperBound.PoKSqS[0].A2 = [
            uint256(38409700536992666532895027864846797641205377237419973885548123673533338862541),            
            uint256(115406101410472928311289938896128200485568846998943861703998801988561762319972),            
            uint256(105653352947424168466331290152291221043423805647389832888633153100213228924616),            
            uint256(106870966079447857245558769850860137306871696266825679503216468610156074555312)            
        ];
        proof.proofOfUpperBound.PoKSqS[0].x = [
            uint256(0),            
            uint256(0),            
            uint256(0),            
            uint256(94866456891408068425925678310425054940450623238131204149418916615547041922504)            
        ];
        proof.proofOfUpperBound.PoKSqS[0].w1 = [
            uint256(0),            
            uint256(0),            
            uint256(43946402494837203989951295786051693781763929936629760192831693574999045394656),            
            uint256(90491323269511095332843609447720950963550933132477105976408973286849968739167)            
        ];
        proof.proofOfUpperBound.PoKSqS[0].w2 = [
            uint256(0),            
            uint256(0),            
            uint256(21210891093182506460782251226327250497297170060286488671713204597836664695210),            
            uint256(69941654714181606164385122026864785045759171477628438668447051016712666642927)            
        ];
        proof.proofOfUpperBound.PoKSqS[0].w2IsNegative = true;
        proof.proofOfUpperBound.PoKSqS[1].squareRoot = [
            uint256(6814128154710986766257727848901307857389126204135067776834073478278294059330),            
            uint256(84468552818831419655159824745693496883222956066879559900929138903579561149820),            
            uint256(104319844623103647099450468344970185903967552187972180303799498426468803561589),            
            uint256(33603559441486185501741884049353344737286534251071913039280871642074657707587)            
        ];
        proof.proofOfUpperBound.PoKSqS[1].A1 = [
            uint256(3585843469161272687991585753574481111979450612490062829179313758938347737883),            
            uint256(54507329621496349501817914919184969043412458550489390376498284404977935975987),            
            uint256(106115952453714950777061016117222120144842091718019660555596097799049411065797),            
            uint256(26236174518745073003650637135622610073335264807174767116436642617387947481887)            
        ];
        proof.proofOfUpperBound.PoKSqS[1].A2 = [
            uint256(36751223789387006613686810193499116306960920556403154726877885852363608720893),            
            uint256(79757348687470118221026615236511409387510973218190474576932470117188819860039),            
            uint256(90401837356690573928032034572883217818066097104093686777771936454380784804765),            
            uint256(73442087761987262640210246294728306678058085971845902955591786336654290051461)            
        ];
        proof.proofOfUpperBound.PoKSqS[1].x = [
            uint256(0),            
            uint256(0),            
            uint256(2),            
            uint256(30550639993878552273772770522413387633641422339193758404608661749897189739098)            
        ];
        proof.proofOfUpperBound.PoKSqS[1].w1 = [
            uint256(0),            
            uint256(0),            
            uint256(839142311484573729040817166442631321127636095431683608969501123216537807884),            
            uint256(71123953506862329713918023176410094978561734317080266360831076007041695543197)            
        ];
        proof.proofOfUpperBound.PoKSqS[1].w2 = [
            uint256(0),            
            uint256(0),            
            uint256(2862704653714099014381656210338910508435272750033104963128691726666279394483),            
            uint256(55464517796604411887691092407939877539886011283090419856758005250445150012483)            
        ];
        proof.proofOfUpperBound.PoKSqS[1].w2IsNegative = true;
        proof.proofOfUpperBound.PoKSqS[2].squareRoot = [
            uint256(28740185849579033849862286449633229618768749658741132802839172330585866869003),            
            uint256(40725583520023528695298069456234399615319612345203818587054656389546786580159),            
            uint256(39504512790368452175602000542866623545761894627128756932301389819659538412978),            
            uint256(109466283087565605790064498903997367053965817167557739715240755040627570544094)            
        ];
        proof.proofOfUpperBound.PoKSqS[2].A1 = [
            uint256(35241573936644624089597497575493590947372573197904755656584292135827662394416),            
            uint256(19590764240305229353829872300732972293659086518560177213827456425638352551768),            
            uint256(67341690052577445593101687948093472037372303188745378427531483787365444731390),            
            uint256(91771459732405846739939805631764657874022837517310172192240125039500166049485)            
        ];
        proof.proofOfUpperBound.PoKSqS[2].A2 = [
            uint256(31172286118327340173011576930447371478605422208093124176299327977105739705221),            
            uint256(51773831440140735186706662332297376304632369521272252912291256182605054168594),            
            uint256(28408290389784554887590466111115887186306573218570221135641726972903101590917),            
            uint256(81151282625363903338702623979241549543716233231783240868869494910153918021655)            
        ];
        proof.proofOfUpperBound.PoKSqS[2].x = [
            uint256(0),            
            uint256(0),            
            uint256(14),            
            uint256(92427884554051553975970305046105659552391801345472721740053415784742924035227)            
        ];
        proof.proofOfUpperBound.PoKSqS[2].w1 = [
            uint256(0),            
            uint256(0),            
            uint256(83304042992521659278051258085350065371708962235159924255825959298320802002180),            
            uint256(114252882185404767192886572134053486164829286737990329298770690017785744762233)            
        ];
        proof.proofOfUpperBound.PoKSqS[2].w2 = [
            uint256(0),            
            uint256(9),            
            uint256(24421227050010091750305570572771700267114515490767594434477702526900072061357),            
            uint256(83936214869530961234087821568198765386467225463148494540147641385495113110796)            
        ];
        proof.proofOfUpperBound.PoKSqS[2].w2IsNegative = true;

        proof.proofOfUpperBound.PoKSEq.A1 = [
            uint256(27664140543603731753729896628842143085159466682358146197559124497629057760310),
            uint256(13078610348131356017819101961568165824539456811601352262866979779635778571195),
            uint256(40123083868832514286012992748742229955971120819974647729474989823101983730836),
            uint256(24257204390473135432681612273495177657541954648908586862771014656225339926908)
        ];
        proof.proofOfUpperBound.PoKSEq.A2 = [
            uint256(11636230868700246990017917524445276475932539124153982274903722564252953202415),
            uint256(35851846388119727390802596093932392278946580660238966532828915657436861261172),
            uint256(82362787535412499469887999194309879757342191782462840622418226076778711767949),
            uint256(28767791174463368532298779275345594145195704890674039444668120435493190783308)
        ];
        proof.proofOfUpperBound.PoKSEq.x = [
            uint256(0),
            uint256(0),
            uint256(144),
            uint256(72838158842943357753548777018912041621535619485767495716218994482346921837143)
        ];
        proof.proofOfUpperBound.PoKSEq.w1 = [
            uint256(0),
            uint256(0),
            uint256(89228610988251072642244408924233017628109880336555985302853737556915214385551),
            uint256(62981526251987158761718319935924538729218893476179446931260167897368106031838)
        ];
        proof.proofOfUpperBound.PoKSEq.w2 = [
            uint256(0),
            uint256(1),
            uint256(8502683901662641485295905333470845502938247647030333290478711164355202856854),
            uint256(1316749480089096595857088055916159413739321499910052629423742164590429531207)
        ];

        vm.prank(address(0xc0ffee2c0de));
        auction.placeBid(1, pp, bid, proof);
    }
}

pragma solidity ^0.8;

import 'forge-std/Test.sol';
import '../src/LibPrime.sol';

contract LibPrimeWrapper {
    using LibPrime for *;
    
    function millerRabin(uint256 n) external view {
        n.millerRabin();
    }

    function pocklington(uint256 n, LibPrime.PocklingtonStep[] memory certificate) external view {
        n.pocklington(certificate);
    }
}

contract LibPrimeTest is Test {
    LibPrimeWrapper lib;

    function setUp() external {
        lib = new LibPrimeWrapper();
    }

    function testMillerRabinPrimes() external view {
        lib.millerRabin(1125540086003892878803180776828183430567643582896516824516711208213767778259);
        lib.millerRabin(8151264910564214172552510538961784892584498710314126382318393854523032748717);
        lib.millerRabin(9341551731633778114822211379357199272851770827068248495866801830534051079929);
        lib.millerRabin(6383743443909871561251952811638977086566121113380770830041649864793597646919);
        lib.millerRabin(2197237718394458030831647368114264829507199079704407667327722758706981233497);
        lib.millerRabin(9064410868229390086903624029203948821248589545509547153592200186831638728037);
        lib.millerRabin(1799466658399057863907043434608765089771426415844247818936512270861804814529);
        lib.millerRabin(7958107354969503546281116282192284922725110310373243636780351171294849091149);
        lib.millerRabin(6233608841289520883910733449408872496191252688032601148221449555432858393371);
        lib.millerRabin(8232380694307874843762241985653295453383187296264055776639176195540846588177);
        lib.millerRabin(5034174091600194978581305209190743984142140769305288608948960772413483626687);
        lib.millerRabin(8340069717972680297994903766600336241596238101580434803328056533048918734499);
        lib.millerRabin(1400537736944484887219968349997533796837304349170394400672628030568034687019);
        lib.millerRabin(7520612482180968453530128273879667845425382183748651655131527203600612317503);
        lib.millerRabin(1568708150223417680875870983919763865151824932396420592501674440793940383849);
    }

    function testMillerRabinComposites() external {
        vm.expectRevert(LibPrime.MillerRabinCheckFailed.selector);
        lib.millerRabin(77964831525692884797883941280343483705963436342330276397207500137689802540683);
        vm.expectRevert(LibPrime.MillerRabinCheckFailed.selector);
        lib.millerRabin(82759076614562733566162717800611268120219491424231847353865427758691245064713);
        vm.expectRevert(LibPrime.MillerRabinCheckFailed.selector);
        lib.millerRabin(79569617363601924884153431348317756325168711481228499021767957072125679353463);
        vm.expectRevert(LibPrime.MillerRabinCheckFailed.selector);
        lib.millerRabin(96456030341838941027885660248303830685767675352263886385505714885252735264761);
        vm.expectRevert(LibPrime.MillerRabinCheckFailed.selector);
        lib.millerRabin(87303596289265269243314105546076342324770676247491661794301909147693304678629);
        vm.expectRevert(LibPrime.MillerRabinCheckFailed.selector);
        lib.millerRabin(89418699728448612365273532859219711591469699186896323234970199605383616796611);
        vm.expectRevert(LibPrime.MillerRabinCheckFailed.selector);
        lib.millerRabin(102686483693295261482374501469692601621691881805129823059161026023136393467521);
        vm.expectRevert(LibPrime.MillerRabinCheckFailed.selector);
        lib.millerRabin(100827321586573390103410299914251806613088577895591410890837411469484045257943);
        vm.expectRevert(LibPrime.MillerRabinCheckFailed.selector);
        lib.millerRabin(94128134159363765893818739739984830816830611868110630592828808089947398172777);
        vm.expectRevert(LibPrime.MillerRabinCheckFailed.selector);
        lib.millerRabin(108085637192410575789366279024874286273962525672256069022303443544858097144649);
        vm.expectRevert(LibPrime.MillerRabinCheckFailed.selector);
        lib.millerRabin(96180706847834726148648760777164730946291489426377513905027404959537647930361);
        vm.expectRevert(LibPrime.MillerRabinCheckFailed.selector);
        lib.millerRabin(87076567172118503597188860638837644441587221163921968400109407171198457539427);
        vm.expectRevert(LibPrime.MillerRabinCheckFailed.selector);
        lib.millerRabin(70666671983287789261443601580170993214444162055061702589752320932490682520563);
        vm.expectRevert(LibPrime.MillerRabinCheckFailed.selector);
        lib.millerRabin(74923400682541913227386583453207489840788830780999066633545322166801156807827);
        vm.expectRevert(LibPrime.MillerRabinCheckFailed.selector);
        lib.millerRabin(98564863894178100815105859857252021763531252705165621436813233429818583039041);
    }

    function testPocklington() external view {
        LibPrime.PocklingtonStep[] memory certificate = new LibPrime.PocklingtonStep[](6);

        // 9341551731633778114822211379357199272851770827068248495866801830534051079929 - 1 = 2^3 * 79 * 599 * 114377 * 1206478843 * 34013583587 * (5257318886781097903082858151842050831906276303)
        certificate[0].F = 5257318886781097903082858151842050831906276303;
        certificate[0].R = 1776866104721552499405530730376;
        certificate[0].nums = new LibPrime.PocklingtonNums[](1);
        certificate[0].nums[0] = LibPrime.PocklingtonNums(5257318886781097903082858151842050831906276303, 1, 2);

        // 5257318886781097903082858151842050831906276303 - 1 = 2 * 3 * (2473) * 4099 * 12821477 * 7379696647 * (913554513665210204509)
        certificate[1].F = 2259220312294064835750757;
        certificate[1].R = 2327050114666636501686;
        certificate[1].nums = new LibPrime.PocklingtonNums[](2);
        certificate[1].nums[0] = LibPrime.PocklingtonNums(913554513665210204509, 1, 2);
        certificate[1].nums[1] = LibPrime.PocklingtonNums(2473, 1, 2);

        // 913554513665210204509 - 1 = 2^2 * 3 * 7 * 11897 * (914150539817171)
        certificate[2].F = 914150539817171;
        certificate[2].R = 999348;
        certificate[2].nums = new LibPrime.PocklingtonNums[](1);
        certificate[2].nums[0] = LibPrime.PocklingtonNums(914150539817171, 1, 2);

        // 2473 - 1 = 2^3 * 3 * (103)
        certificate[3].F = 103;
        certificate[3].R = 24;
        certificate[3].nums = new LibPrime.PocklingtonNums[](1);
        certificate[3].nums[0] = LibPrime.PocklingtonNums(103, 1, 2);

        // 914150539817171 - 1 = 2 * 5 * 37^3 * (103 * 17521663)
        certificate[4].F = 1804731289;
        certificate[4].R = 506530;
        certificate[4].nums = new LibPrime.PocklingtonNums[](2);
        certificate[4].nums[0] = LibPrime.PocklingtonNums(17521663, 1, 2);
        certificate[4].nums[1] = LibPrime.PocklingtonNums(103, 1, 2);

        // 17521663 - 1 = 2 * 3 * (17 * 283) * 607
        certificate[5].F = 4811;
        certificate[5].R = 3642;
        certificate[5].nums = new LibPrime.PocklingtonNums[](2);
        certificate[5].nums[0] = LibPrime.PocklingtonNums(17, 1, 2);
        certificate[5].nums[1] = LibPrime.PocklingtonNums(283, 1, 2);

        lib.pocklington(
            9341551731633778114822211379357199272851770827068248495866801830534051079929,
            certificate
        );
    }
}
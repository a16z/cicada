pragma solidity ^0.8;

import "forge-std/Test.sol";
import "../src/LibBigMath.sol";

contract LibBigMathTest is Test {
    using LibBigMath for *;

    function testAddCommutative(uint256[8] memory a, uint256[8] memory b)
        public
    {
        unchecked {
            vm.assume(a[0] + b[0] > a[0]);
            vm.assume(a[0] + b[0] < type(uint256).max);
        }
        LibBigMath.BigNumber2048 memory bigA = LibBigMath.BigNumber2048(a);
        LibBigMath.BigNumber2048 memory bigB = LibBigMath.BigNumber2048(b);
        LibBigMath.BigNumber2048 memory sum1 = bigA.add(bigB);
        LibBigMath.BigNumber2048 memory sum2 = bigB.add(bigA);
        assertTrue(sum1.eq(sum2));
    }

    function testAddSub(uint256[8] memory a, uint256[8] memory b)
        public
    {
        unchecked {
            vm.assume(a[0] + b[0] > a[0]);
            vm.assume(a[0] + b[0] < type(uint256).max);
        }
        LibBigMath.BigNumber2048 memory bigA = LibBigMath.BigNumber2048(a);
        LibBigMath.BigNumber2048 memory bigB = LibBigMath.BigNumber2048(b);
        LibBigMath.BigNumber2048 memory sum = bigA.add(bigB);
        assertTrue(sum.sub(bigB).eq(bigA));
        assertTrue(sum.sub(bigA).eq(bigB));
    }

    function testSubAdd(uint256[8] memory a, uint256[8] memory b)
        public
    {
        LibBigMath.BigNumber2048 memory bigA = LibBigMath.BigNumber2048(a);
        LibBigMath.BigNumber2048 memory bigB = LibBigMath.BigNumber2048(b);
        vm.assume(bigA.gte(bigB));
        assertTrue(bigA.sub(bigB).add(bigB).eq(bigA));
    }
}

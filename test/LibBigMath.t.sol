pragma solidity ^0.8;

import 'forge-std/Test.sol';
import '../src/LibBigMath.sol';

contract LibBigMathTest is Test {
    using LibBigMath for *;

    function testReferenceAdd(uint256[8] memory a, uint256[8] memory b)
        public
    {
        unchecked {
            vm.assume(a[0] + b[0] > a[0]);
            vm.assume(a[0] + b[0] < type(uint256).max);
        }
        LibBigMath.BigNumber2048 memory bigA = LibBigMath.BigNumber2048(a);
        LibBigMath.BigNumber2048 memory bigB = LibBigMath.BigNumber2048(b);
        LibBigMath.BigNumber2048 memory pythonResult = _decodeBigNumber(_runPythonReference('add', bigA, bigB));
        assertTrue(bigA.add(bigB).eq(pythonResult));
    }

    function testReferenceSub(uint256[8] memory a, uint256[8] memory b)
        public
    {
        LibBigMath.BigNumber2048 memory bigA = LibBigMath.BigNumber2048(a);
        LibBigMath.BigNumber2048 memory bigB = LibBigMath.BigNumber2048(b);
        vm.assume(bigA.gte(bigB));
        LibBigMath.BigNumber2048 memory pythonResult = _decodeBigNumber(_runPythonReference('sub', bigA, bigB));
        assertTrue(bigA.sub(bigB).eq(pythonResult));
    }

    function testReferenceGte(uint256[8] memory a, uint256[8] memory b)
        public
    {
        LibBigMath.BigNumber2048 memory bigA = LibBigMath.BigNumber2048(a);
        LibBigMath.BigNumber2048 memory bigB = LibBigMath.BigNumber2048(b);
        bool pythonResult = _decodeBool(_runPythonReference('gte', bigA, bigB));
        assertEq(bigA.gte(bigB), pythonResult);
    }

    function testReferenceLte(uint256[8] memory a, uint256[8] memory b)
        public
    {
        LibBigMath.BigNumber2048 memory bigA = LibBigMath.BigNumber2048(a);
        LibBigMath.BigNumber2048 memory bigB = LibBigMath.BigNumber2048(b);
        bool pythonResult = _decodeBool(_runPythonReference('lte', bigA, bigB));
        assertEq(bigA.lte(bigB), pythonResult);
    }

    function testReferenceAddMod(
        uint256[8] memory a, 
        uint256[8] memory b,
        uint256[8] memory m
    )
        public
    {
        unchecked {
            vm.assume(a[0] + b[0] > a[0]);
            vm.assume(a[0] + b[0] < type(uint256).max);
        }
        LibBigMath.BigNumber2048 memory bigA = LibBigMath.BigNumber2048(a);
        LibBigMath.BigNumber2048 memory bigB = LibBigMath.BigNumber2048(b);
        LibBigMath.BigNumber2048 memory bigM = LibBigMath.BigNumber2048(m);
        vm.assume(bigA.lt(bigM) && bigB.lt(bigM));
        LibBigMath.BigNumber2048 memory pythonResult = _decodeBigNumber(_runPythonReference(
            'addMod', 
            bigA, 
            bigB, 
            bigM
        ));
        LibBigMath.BigNumber2048 memory solidityResult = bigA.addMod(bigB, bigM);
        assertTrue(solidityResult.eq(pythonResult));
    }

    function testReferenceSubMod(
        uint256[8] memory a, 
        uint256[8] memory b,
        uint256[8] memory m
    )
        public
    {
        LibBigMath.BigNumber2048 memory bigA = LibBigMath.BigNumber2048(a);
        LibBigMath.BigNumber2048 memory bigB = LibBigMath.BigNumber2048(b);
        LibBigMath.BigNumber2048 memory bigM = LibBigMath.BigNumber2048(m);
        vm.assume(bigA.lt(bigM) && bigB.lt(bigM));
        LibBigMath.BigNumber2048 memory pythonResult = _decodeBigNumber(_runPythonReference(
            'subMod', 
            bigA, 
            bigB, 
            bigM
        ));
        LibBigMath.BigNumber2048 memory solidityResult = bigA.subMod(bigB, bigM);
        assertTrue(solidityResult.eq(pythonResult));
    }

    function testGasAdd(uint256[8] memory a, uint256[8] memory b)
        public
        pure
    {
        unchecked {
            vm.assume(a[0] + b[0] > a[0]);
            vm.assume(a[0] + b[0] < type(uint256).max);
        }
        LibBigMath.BigNumber2048 memory bigA = LibBigMath.BigNumber2048(a);
        LibBigMath.BigNumber2048 memory bigB = LibBigMath.BigNumber2048(b);
        bigA.add(bigB);
    }

    function testGasSub(uint256[8] memory a, uint256[8] memory b)
        public
        pure
    {
        LibBigMath.BigNumber2048 memory bigA = LibBigMath.BigNumber2048(a);
        LibBigMath.BigNumber2048 memory bigB = LibBigMath.BigNumber2048(b);
        vm.assume(bigA.gte(bigB));
        bigA.sub(bigB);
    }

    function testGasEq(uint256[8] memory a, uint256[8] memory b)
        public
        pure
    {
        LibBigMath.BigNumber2048 memory bigA = LibBigMath.BigNumber2048(a);
        LibBigMath.BigNumber2048 memory bigB = LibBigMath.BigNumber2048(b);
        bigA.eq(bigB);
    }

    function testGasGte(uint256[8] memory a, uint256[8] memory b)
        public
        pure
    {
        LibBigMath.BigNumber2048 memory bigA = LibBigMath.BigNumber2048(a);
        LibBigMath.BigNumber2048 memory bigB = LibBigMath.BigNumber2048(b);
        bigA.gte(bigB);
    }

    function testGasLte(uint256[8] memory a, uint256[8] memory b)
        public
        pure
    {
        LibBigMath.BigNumber2048 memory bigA = LibBigMath.BigNumber2048(a);
        LibBigMath.BigNumber2048 memory bigB = LibBigMath.BigNumber2048(b);
        bigA.lte(bigB);
    }

    function testGasAddMod(
        uint256[8] memory a, 
        uint256[8] memory b,
        uint256[8] memory m
    )
        public
        pure
    {
        unchecked {
            vm.assume(a[0] + b[0] > a[0]);
            vm.assume(a[0] + b[0] < type(uint256).max);
        }
        LibBigMath.BigNumber2048 memory bigA = LibBigMath.BigNumber2048(a);
        LibBigMath.BigNumber2048 memory bigB = LibBigMath.BigNumber2048(b);
        LibBigMath.BigNumber2048 memory bigM = LibBigMath.BigNumber2048(m);
        vm.assume(bigA.lt(bigM) && bigB.lt(bigM));
        bigA.addMod(bigB, bigM);
    }

    function testGasSubMod(
        uint256[8] memory a, 
        uint256[8] memory b,
        uint256[8] memory m
    )
        public
        pure
    {
        LibBigMath.BigNumber2048 memory bigA = LibBigMath.BigNumber2048(a);
        LibBigMath.BigNumber2048 memory bigB = LibBigMath.BigNumber2048(b);
        LibBigMath.BigNumber2048 memory bigM = LibBigMath.BigNumber2048(m);
        vm.assume(bigA.lt(bigM) && bigB.lt(bigM));
        bigA.subMod(bigB, bigM);
    }

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

    // ================================================================

    function _decodeBigNumber(bytes memory encoded)
        private
        pure
        returns (LibBigMath.BigNumber2048 memory c)
    {
        c.words = abi.decode(encoded, (uint256[8]));
        return c;
    }

    function _decodeBool(bytes memory encoded)
        private
        pure
        returns (bool)
    {
        return abi.decode(encoded, (bool));
    }

    function _runPythonReference(
        string memory operation,
        LibBigMath.BigNumber2048 memory a, 
        LibBigMath.BigNumber2048 memory b   
    )
        private
        returns (bytes memory pythonResult)
    {
        bytes memory packedA = abi.encodePacked(a.words);
        bytes memory packedB = abi.encodePacked(b.words);

        string[] memory pythonCommand = new string[](7);
        pythonCommand[0] = 'python3';
        pythonCommand[1] = 'test/big_math_reference.py';
        pythonCommand[2] = '--operation';
        pythonCommand[3] = operation;
        pythonCommand[4] = '--inputs';
        pythonCommand[5] = toHexString(packedA);
        pythonCommand[6] = toHexString(packedB);
        
        return vm.ffi(pythonCommand);
    }

    function _runPythonReference(
        string memory operation,
        LibBigMath.BigNumber2048 memory a, 
        LibBigMath.BigNumber2048 memory b,
        LibBigMath.BigNumber2048 memory c
    )
        private
        returns (bytes memory pythonResult)
    {
        bytes memory packedA = abi.encodePacked(a.words);
        bytes memory packedB = abi.encodePacked(b.words);
        bytes memory packedC = abi.encodePacked(c.words);

        string[] memory pythonCommand = new string[](8);
        pythonCommand[0] = 'python3';
        pythonCommand[1] = 'test/big_math_reference.py';
        pythonCommand[2] = '--operation';
        pythonCommand[3] = operation;
        pythonCommand[4] = '--inputs';
        pythonCommand[5] = toHexString(packedA);
        pythonCommand[6] = toHexString(packedB);
        pythonCommand[7] = toHexString(packedC);
        
        return vm.ffi(pythonCommand);
    }

    function toHexString(bytes memory input) public pure returns (string memory) {
        require(input.length < type(uint256).max / 2 - 1);
        bytes16 symbols = '0123456789abcdef';
        bytes memory hex_buffer = new bytes(2 * input.length + 2);
        hex_buffer[0] = '0';
        hex_buffer[1] = 'x';

        uint pos = 2;
        uint256 length = input.length;
        for (uint i = 0; i < length; ++i) {
            uint _byte = uint8(input[i]);
            hex_buffer[pos++] = symbols[_byte >> 4];
            hex_buffer[pos++] = symbols[_byte & 0xf];
        }
        return string(hex_buffer);
    }
}

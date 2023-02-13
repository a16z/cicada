pragma solidity ^0.8;

import 'forge-std/Test.sol';
import '../src/LibUint2048.sol';
import '../src/LibUint1024.jinja.sol';

contract LibUint2048Test is Test {
    using LibUint2048 for *;
    using LibUint1024 for *;

    function testBigExpMod(
        uint256[8] calldata base, 
        // uint256[4] calldata exponent, 
        // uint128 exponent,
        uint256[8] calldata modulus
    )
        external
    {
        // vm.assume(exponent[0] > (1 << 255));
        // vm.assume(exponent > (1 << 127));
        uint gasBefore = gasleft();
        base.expMod(uint256(1), modulus);
        uint gasAfter = gasleft();
        console.log(gasBefore - gasAfter);
    }

    function testBigMulMod(
        uint256[4] calldata x, 
        uint256[4] calldata y, 
        uint256[4] calldata modulus
    )
        external
    {
        vm.assume(x.lt(modulus));
        vm.assume(y.lt(modulus));
        x.mulMod(y, modulus);
        // base.expMod(uint256(exponent), modulus);
    }

    function testReferenceAdd(uint256[8] memory a, uint256[8] memory b)
        public
        noOverflow(a, b)
    {
        uint256[8] memory pythonResult = _decodeBigNumber(_runPythonReference('add', a, b));
        assertTrue(a.add(b).eq(pythonResult));
    }

    function testReferenceSub(uint256[8] memory a, uint256[8] memory b)
        public
    {
        vm.assume(a.gte(b));
        uint256[8] memory pythonResult = _decodeBigNumber(_runPythonReference('sub', a, b));
        assertTrue(a.sub(b).eq(pythonResult));
    }

    function testReferenceGte(uint256[8] memory a, uint256[8] memory b)
        public
    {
        bool pythonResult = _decodeBool(_runPythonReference('gte', a, b));
        assertEq(a.gte(b), pythonResult);
    }

    function testReferenceLte(uint256[8] memory a, uint256[8] memory b)
        public
    {
        bool pythonResult = _decodeBool(_runPythonReference('lte', a, b));
        assertEq(a.lte(b), pythonResult);
    }

    function testReferenceAddMod(
        uint256[8] memory a, 
        uint256[8] memory b,
        uint256[8] memory m
    )
        public
        noOverflow(a, b)
    {
        vm.assume(a.lt(m) && b.lt(m));
        uint256[8] memory pythonResult = _decodeBigNumber(_runPythonReference(
            'addMod', 
            a, 
            b, 
            m
        ));
        uint256[8] memory solidityResult = a.addMod(b, m);
        assertTrue(solidityResult.eq(pythonResult));
    }

    function testReferenceSubMod(
        uint256[8] memory a, 
        uint256[8] memory b,
        uint256[8] memory m
    )
        public
    {
        vm.assume(a.lt(m) && b.lt(m));
        uint256[8] memory pythonResult = _decodeBigNumber(_runPythonReference(
            'subMod', 
            a, 
            b, 
            m
        ));
        uint256[8] memory solidityResult = a.subMod(b, m);
        assertTrue(solidityResult.eq(pythonResult));
    }

    function testReferenceExpMod(
        uint256[8] memory a, 
        uint256 e,
        uint256[8] memory m
    )
        public
    {
        uint256[8] memory pythonResult = _decodeBigNumber(_runPythonExpMod(
            a, 
            e,
            m
        ));
        uint256[8] memory solidityResult = a.expMod(e, m);
        assertTrue(solidityResult.eq(pythonResult));
    }

    function testReferenceMulMod(
        uint256[8] memory a, 
        uint256[8] memory b,
        uint256[8] memory m
    )
        public
        noOverflow(a, b)
    {
        vm.assume(a.lt(m) && b.lt(m));
        uint256[8] memory pythonResult = _decodeBigNumber(_runPythonMulMod(
            a, 
            b,
            m
        ));
        uint256[8] memory solidityResult = a.mulMod(b, m);
        assertTrue(solidityResult.eq(pythonResult));
    }

    function testGasAdd(uint256[8] memory a, uint256[8] memory b)
        public
        pure
        noOverflow(a, b)
    {
        a.add(b);
    }

    function testGasSub(uint256[8] memory a, uint256[8] memory b)
        public
        pure
    {
        vm.assume(a.gte(b));
        a.sub(b);
    }

    function testGasEq(uint256[8] memory a, uint256[8] memory b)
        public
        pure
    {
        a.eq(b);
    }

    function testGasGte(uint256[8] memory a, uint256[8] memory b)
        public
        pure
    {
        a.gte(b);
    }

    function testGasLte(uint256[8] memory a, uint256[8] memory b)
        public
        pure
    {
        a.lte(b);
    }

    function testGasAddMod(
        uint256[8] memory a, 
        uint256[8] memory b,
        uint256[8] memory m
    )
        public
        pure
        noOverflow(a, b)
    {
        vm.assume(a.lt(m) && b.lt(m));
        a.addMod(b, m);
    }

    function testGasSubMod(
        uint256[8] memory a, 
        uint256[8] memory b,
        uint256[8] memory m
    )
        public
        pure
    {
        vm.assume(a.lt(m) && b.lt(m));
        a.subMod(b, m);
    }

    function testGasExpMod(
        uint256[8] memory a, 
        uint256 e,
        uint256[8] memory m
    )
        public
        view
    {
        a.expMod(e, m);
    }

    function testGasMulMod(
        uint256[8] memory a, 
        uint256[8] memory b,
        uint256[8] memory m
    )
        public
        view
        noOverflow(a, b)
    {
        vm.assume(a.lt(m) && b.lt(m));
        a.mulMod(b, m);
    }

    function testAddCommutative(uint256[8] memory a, uint256[8] memory b)
        public
        noOverflow(a, b)
    {
        uint256[8] memory sum1 = a.add(b);
        uint256[8] memory sum2 = b.add(a);
        assertTrue(sum1.eq(sum2));
    }

    function testAddSub(uint256[8] memory a, uint256[8] memory b)
        public
        noOverflow(a, b)
    {
        uint256[8] memory sum = a.add(b);
        assertTrue(sum.sub(b).eq(a));
        assertTrue(sum.sub(a).eq(b));
    }

    function testSubAdd(uint256[8] memory a, uint256[8] memory b)
        public
    {
        vm.assume(a.gte(b));
        assertTrue(a.sub(b).add(b).eq(a));
    }

    function testExpModSmall(uint128 a, uint128 e, uint128 m)
        public
    {
        vm.assume(m > 0);
        uint256 expectedResult = 1;
        if (e != 0) {
            uint256 pow = uint256(a % m);
            expectedResult = (e & 1 != 0) ? pow : 1;
            for (uint256 i = 1; (1 << i) <= e; i++) {
                pow = (pow ** 2) % m;
                if (e & (1 << i) != 0) {
                    expectedResult = (expectedResult * pow) % m;
                }
            }
        }

        uint256[8] memory bigA = uint256(a).toUint2048();
        uint256[8] memory bigM = m.toUint2048();
        assertTrue(bigA.expMod(e, bigM).eq(expectedResult.toUint2048()));
    }

    function testMulModSmall(uint256 a, uint256 b, uint256 m)
        public
    {
        vm.assume(a < m && b < m);
        vm.assume(mulmod(a, b, m) <= type(uint256).max / 4);
        uint256[8] memory bigA = a.toUint2048();
        uint256[8] memory bigB = b.toUint2048();
        uint256[8] memory bigM = m.toUint2048();

        uint256 expectedResult = (4 * mulmod(a, b, m)) % m;
        assertTrue(bigA.mulMod(bigB, bigM).eq(expectedResult.toUint2048()));
    }

    // ================================================================

    modifier noOverflow(uint256[8] memory a, uint256[8] memory b) {
        unchecked {
            vm.assume(a[0] + b[0] > a[0]);
            vm.assume(a[0] + b[0] < type(uint256).max);
        }
        _;
    }

    function _decodeBigNumber(bytes memory encoded)
        private
        pure
        returns (uint256[8] memory c)
    {
        c = abi.decode(encoded, (uint256[8]));
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
        uint256[8] memory a, 
        uint256[8] memory b   
    )
        private
        returns (bytes memory pythonResult)
    {
        bytes memory packedA = abi.encodePacked(a);
        bytes memory packedB = abi.encodePacked(b);

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
        uint256[8] memory a, 
        uint256[8] memory b,
        uint256[8] memory c
    )
        private
        returns (bytes memory pythonResult)
    {
        bytes memory packedA = abi.encodePacked(a);
        bytes memory packedB = abi.encodePacked(b);
        bytes memory packedC = abi.encodePacked(c);

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

    function _runPythonExpMod(
        uint256[8] memory a, 
        uint256 e,
        uint256[8] memory m
    )
        private
        returns (bytes memory pythonResult)
    {
        bytes memory packedA = abi.encodePacked(a);
        bytes memory packedE = abi.encodePacked(e);
        bytes memory packedM = abi.encodePacked(m);

        string[] memory pythonCommand = new string[](8);
        pythonCommand[0] = 'python3';
        pythonCommand[1] = 'test/big_math_reference.py';
        pythonCommand[2] = '--operation';
        pythonCommand[3] = 'expMod';
        pythonCommand[4] = '--inputs';
        pythonCommand[5] = toHexString(packedA);
        pythonCommand[6] = toHexString(packedE);
        pythonCommand[7] = toHexString(packedM);
        
        return vm.ffi(pythonCommand);
    }

    function _runPythonMulMod(
        uint256[8] memory a, 
        uint256[8] memory b, 
        uint256[8] memory m
    )
        private
        returns (bytes memory pythonResult)
    {
        bytes memory packedA = abi.encodePacked(a);
        bytes memory packedB = abi.encodePacked(b);
        bytes memory packedM = abi.encodePacked(m);

        string[] memory pythonCommand = new string[](8);
        pythonCommand[0] = 'python3';
        pythonCommand[1] = 'test/big_math_reference.py';
        pythonCommand[2] = '--operation';
        pythonCommand[3] = 'mulMod';
        pythonCommand[4] = '--inputs';
        pythonCommand[5] = toHexString(packedA);
        pythonCommand[6] = toHexString(packedB);
        pythonCommand[7] = toHexString(packedM);
        
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

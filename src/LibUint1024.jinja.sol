pragma solidity ^0.8;

library LibUint1024 {
    using LibUint1024 for *;

    error Overflow(uint256[4] a, uint256[4] b);
    error Underflow(uint256[4] a, uint256[4] b);

    function toUint1024(uint256 x)
        internal 
        pure 
        returns (uint256[4] memory bn) 
    {
        bn[3] = x;
    }

    function add(uint256[4] memory a, uint256[4] memory b) 
        internal 
        pure
        returns (uint256[4] memory c)
    {
        uint256 carry;
        (c, carry) = _add(a, b);
        if (carry != 0) {
            revert Overflow(a, b);
        }
    }

    function sub(uint256[4] memory a, uint256[4] memory b) 
        internal 
        pure
        returns (uint256[4] memory c)
    {
        uint256 carry;
        (c, carry) = _sub(a, b);
        if (carry != 0) {
            revert Underflow(a, b);
        }
    }

    function _add(uint256[4] memory a, uint256[4] memory b) 
        private 
        pure
        returns (uint256[4] memory c, uint256 carry)
    {
        assembly {
            let aWord := mload(add(a, 0x60))
            let bWord := mload(add(b, 0x60))
            let sum := add(aWord, bWord)
            mstore(add(c, 0x60), sum)
            carry := lt(sum, aWord)

            aWord := mload(add(a, 0x40))
            bWord := mload(add(b, 0x40))
            sum := add(aWord, bWord)
            let cWord := add(sum, carry)
            mstore(add(c, 0x40), cWord)
            carry := or(lt(sum, aWord), lt(cWord, sum))

            aWord := mload(add(a, 0x20))
            bWord := mload(add(b, 0x20))
            sum := add(aWord, bWord)
            cWord := add(sum, carry)
            mstore(add(c, 0x20), cWord)
            carry := or(lt(sum, aWord), lt(cWord, sum))

            aWord := mload(a)
            bWord := mload(b)
            sum := add(aWord, bWord)
            cWord := add(sum, carry)
            mstore(c, cWord)
            carry := or(lt(sum, aWord), lt(cWord, sum))
        }
    }

    function _sub(uint256[4] memory a, uint256[4] memory b) 
        private 
        pure
        returns (uint256[4] memory c, uint256 carry)
    {
        assembly {
            let aWord := mload(add(a, 0x60))
            let bWord := mload(add(b, 0x60))
            let diff := sub(aWord, bWord)
            mstore(add(c, 0x60), diff)
            carry := lt(aWord, bWord)

            aWord := mload(add(a, 0x40))
            bWord := mload(add(b, 0x40))
            diff := sub(aWord, bWord)
            mstore(add(c, 0x40), sub(diff, carry))
            carry := or(lt(aWord, bWord), lt(diff, carry))

            aWord := mload(add(a, 0x20))
            bWord := mload(add(b, 0x20))
            diff := sub(aWord, bWord)
            mstore(add(c, 0x20), sub(diff, carry))
            carry := or(lt(aWord, bWord), lt(diff, carry))

            aWord := mload(a)
            bWord := mload(b)
            diff := sub(aWord, bWord)
            mstore(c, sub(diff, carry))
            carry := or(lt(aWord, bWord), lt(diff, carry))
        }
    }

    function eq(uint256[4] memory a, uint256[4] memory b)
        internal
        pure
        returns (bool)
    {
        return
            a[0] == b[0] &&
            a[1] == b[1] &&
            a[2] == b[2] &&
            a[3] == b[3];
    }

    function gt(uint256[4] memory a, uint256[4] memory b)
        internal
        pure
        returns (bool)
    {
        return _gt(a, b, false);
    }

    function gte(uint256[4] memory a, uint256[4] memory b)
        internal
        pure
        returns (bool)
    {
        return _gt(a, b, true);
    }

    function _gt(
        uint256[4] memory a, 
        uint256[4] memory b, 
        bool trueIfEqual
    )
        private
        pure
        returns (bool)
    {
        if (a[0] < b[0]) {
            return false;
        } else if (a[0] > b[0]) {
            return true;
        }        
        if (a[1] < b[1]) {
            return false;
        } else if (a[1] > b[1]) {
            return true;
        }        
        if (a[2] < b[2]) {
            return false;
        } else if (a[2] > b[2]) {
            return true;
        }        
        if (a[3] < b[3]) {
            return false;
        }
        return trueIfEqual || a[3] > b[3];
    }

    function lt(uint256[4] memory a, uint256[4] memory b)
        internal
        pure
        returns (bool)
    {
        return _lt(a, b, false);
    }

    function lte(uint256[4] memory a, uint256[4] memory b)
        internal
        pure
        returns (bool)
    {
        return _lt(a, b, true);
    }

    function _lt(
        uint256[4] memory a, 
        uint256[4] memory b, 
        bool trueIfEqual
    )
        private
        pure
        returns (bool)
    {
        if (a[0] > b[0]) {
            return false;
        } else if (a[0] < b[0]) {
            return true;
        }        
        if (a[1] > b[1]) {
            return false;
        } else if (a[1] < b[1]) {
            return true;
        }        
        if (a[2] > b[2]) {
            return false;
        } else if (a[2] < b[2]) {
            return true;
        }        
        if (a[3] > b[3]) {
            return false;
        }
        return trueIfEqual || a[3] < b[3];
    }

    uint256 private constant MAX_UINT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    function mulMod(uint256[4] memory a, uint256[4] memory b, uint256[4] memory modulus)
        internal
        view
        returns (uint256[4] memory result)
    {
        assembly {
            function addWithCarry(x, y, carry) -> z, updatedCarry {
                z := add(x, y)
                updatedCarry := add(carry, lt(z, x))
            }

            function mul512(x, y) -> r1, r0 {
                let mm := mulmod(x, y, MAX_UINT)
                r0 := mul(x, y)
                r1 := sub(sub(mm, r0), lt(mm, r0))
            }

            let p := mload(0x40)

            let a0 := mload(a)
            let a1 := mload(add(a, 0x20))
            let a2 := mload(add(a, 0x40))
            let a3 := mload(add(a, 0x60))

            let r0 := 0
            let r1 := 0
            let r2 := 0
            let r3 := 0
            let r4 := 0
            let r5 := 0
            let r6 := 0

            let c0 := 0
            let c1 := 0
            let c2 := 0
            let c3 := 0
            let c4 := 0
            let c5 := 0

            let h := 0
            let l := 0

            let bi := mload(add(b, 0x60))

            r6, l := mul512(a3, bi)
            mstore(add(p, 0x140), l)

            r5, l := mul512(a2, bi)
            r6, c5 := addWithCarry(r6, l, 0)
            
            r4, l := mul512(a1, bi)
            r5, c4 := addWithCarry(r5, l, 0)
            
            r3, l := mul512(a0, bi)
            r4, c3 := addWithCarry(r4, l, 0)

            bi := mload(add(b, 0x40))

            h, l := mul512(a3, bi)
            r6, c5 := addWithCarry(r6, l, c5)
            r5, c4 := addWithCarry(r5, h, c4)

            h, l := mul512(a2, bi)
            r5, c4 := addWithCarry(r5, l, c4)
            r4, c3 := addWithCarry(r4, h, c3)

            h, l := mul512(a1, bi)
            r4, c3 := addWithCarry(r4, l, c3)
            r3, c2 := addWithCarry(r3, h, c2)

            h, l := mul512(a0, bi)
            r3, c2 := addWithCarry(r3, l, c2)
            r2, c1 := addWithCarry(r2, h, c1)

            bi := mload(add(b, 0x20))

            h, l := mul512(a3, bi)
            r5, c4 := addWithCarry(r5, l, c4)
            r4, c3 := addWithCarry(r4, h, c3)

            h, l := mul512(a2, bi)
            r4, c3 := addWithCarry(r4, l, c3)
            r3, c2 := addWithCarry(r3, h, c2)

            h, l := mul512(a1, bi)
            r3, c2 := addWithCarry(r3, l, c2)
            r2, c1 := addWithCarry(r2, h, c1)

            h, l := mul512(a0, bi)
            r2, c1 := addWithCarry(r2, l, c1)
            r1, c0 := addWithCarry(r1, h, c0)

            bi := mload(b)

            h, l := mul512(a3, bi)
            r4, c3 := addWithCarry(r4, l, c3)
            r3, c2 := addWithCarry(r3, h, c2)

            h, l := mul512(a2, bi)
            r3, c2 := addWithCarry(r3, l, c2)
            r2, c1 := addWithCarry(r2, h, c1)

            h, l := mul512(a1, bi)
            r2, c1 := addWithCarry(r2, l, c1)
            r1, c0 := addWithCarry(r1, h, c0)

            r0, l := mul512(a0, bi)
            r1, c0 := addWithCarry(r1, l, c0)

            r5 := add(r5, c5)
            c4 := add(c4, lt(r5, c5))

            r4 := add(r4, c4)
            c3 := add(c3, lt(r4, c4))

            r3 := add(r3, c3)
            c2 := add(c2, lt(r3, c3))

            r2 := add(r2, c2)
            c1 := add(c1, lt(r2, c2))

            r1 := add(r1, c1)
            c0 := add(c0, lt(r1, c1))

            mstore(add(p, 0x60), add(r0, c0))

            // Store parameters for the Expmod (0x05) precompile
            mstore(p, 0x100)               // Length of base (8 * 32 = 256 bytes)
            mstore(add(p, 0x20), 0x20)     // Length of exponent
            mstore(add(p, 0x40), 0x80)    // Length of modulus (4 * 32 = 128 bytes)

            // Store the base
            mstore(add(p, 0x80), r1)
            mstore(add(p, 0xa0), r2)
            mstore(add(p, 0xc0), r3)
            mstore(add(p, 0xe0), r4)
            mstore(add(p, 0x100), r5)
            mstore(add(p, 0x120), r6)

            // Store the exponent
            mstore(add(p, 0x160), 1)

            // Use Identity (0x04) precompile to memcpy the modulus
            if iszero(staticcall(gas(), 0x04, modulus, 0x80, add(p, 0x180), 0x80)) {
                revert(0, 0)
            }
            // Call 0x05 (EXPMOD) precompile
            if iszero(staticcall(gas(), 0x05, p, 0x200, result, 0x80)) {
                revert(0, 0)
            }

            // Update free memory pointer
            mstore(0x40, add(p, 0x200))
        }
    }

    function addMod(uint256[4] memory a, uint256[4] memory b, uint256[4] memory modulus)
        internal
        pure
        returns (uint256[4] memory result)
    {
        uint256 carry;
        (result, carry) = _add(a, b);
        if (carry == 1 || result.gte(modulus)) {
            (result, ) = _sub(result, modulus);
        }
    }

    function subMod(uint256[4] memory a, uint256[4] memory b, uint256[4] memory modulus)
        internal
        pure
        returns (uint256[4] memory result)
    {
        if (a.gte(b)) {
            return a.sub(b);
        } else {
            return modulus.sub(b.sub(a));
        }
    }

    function expMod(uint256[4] memory base, uint256 exponent, uint256[4] memory modulus)
        internal
        view
        returns (uint256[4] memory result)
    {
        assembly {
            // Get free memory pointer
            let p := mload(0x40)

            // Store parameters for the Expmod (0x05) precompile
            mstore(p, 0x80)               // Length of base (4 * 32 = 128 bytes)
            mstore(add(p, 0x20), 0x20)     // Length of exponent
            mstore(add(p, 0x40), 0x80)    // Length of modulus (4 * 32 = 128 bytes)

            // Use Identity (0x04) precompile to memcpy the base
            if iszero(staticcall(gas(), 0x04, base, 0x80, add(p, 0x60), 0x80)) {
                revert(0, 0)
            }
            // Store the exponent
            mstore(add(p, 0xe0), exponent)
            // Use Identity (0x04) precompile to memcpy the modulus
            if iszero(staticcall(gas(), 0x04, modulus, 0x80, add(p, 0x100), 0x80)) {
                revert(0, 0)
            }
            // Call 0x05 (EXPMOD) precompile
            if iszero(staticcall(gas(), 0x05, p, 0x180, result, 0x80)) {
                revert(0, 0)
            }

            // Update free memory pointer
            mstore(0x40, add(p, 0x180))
        }
    }

    function expMod(
        uint256[4] memory base, 
        uint256[4] memory exponent, 
        uint256[4] memory modulus
    )
        internal
        view
        returns (uint256[4] memory result)
    {
        assembly {
            // Get free memory pointer
            let p := mload(0x40)

            // Store parameters for the Expmod (0x05) precompile
            mstore(p, 0x80)               // Length of base (4 * 32 = 128 bytes)
            mstore(add(p, 0x20), 0x80)    // Length of exponent (4 * 32 = 128 bytes)
            mstore(add(p, 0x40), 0x80)    // Length of modulus (4 * 32 = 128 bytes)

            // Use Identity (0x04) precompile to memcpy the base
            if iszero(staticcall(gas(), 0x04, base, 0x80, add(p, 0x60), 0x80)) {
                revert(0, 0)
            }
            // Use Identity (0x04) precompile to memcpy the exponent
            if iszero(staticcall(gas(), 0x04, exponent, 0x80, add(p, 0xe0), 0x80)) {
                revert(0, 0)
            }
            // Use Identity (0x04) precompile to memcpy the modulus
            if iszero(staticcall(gas(), 0x04, modulus, 0x80, add(p, 0x160), 0x80)) {
                revert(0, 0)
            }
            // Call 0x05 (EXPMOD) precompile
            if iszero(staticcall(gas(), 0x05, p, 0x1e0, result, 0x80)) {
                revert(0, 0)
            }

            // Update free memory pointer
            mstore(0x40, add(p, 0x1e0))
        }
    }
}
// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8;


/// @dev A library for big (1024-bit) number arithmetic, including modular arithmetic
///      operations.
library LibUint1024 {
    using LibUint1024 for *;

    uint256 private constant MAX_UINT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    error Overflow(uint256[4] a, uint256[4] b);
    error Underflow(uint256[4] a, uint256[4] b);

    /// @dev Converts a uint256 to its 1024-bit representation.
    function toUint1024(uint256 x)
        internal 
        pure 
        returns (uint256[4] memory bn) 
    {
        bn[3] = x;
    }

    /// @dev Computes a + b, reverting on overflow.
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

    /// @dev Computes a - b, reverting on underflow.
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

    /// @dev Computes a + b, returning the 1024-bit result and the carry bit.
    function _add(uint256[4] memory a, uint256[4] memory b) 
        internal
        pure
        returns (uint256[4] memory c, uint256 carry)
    {
        assembly {
            // c[3] = a[3] + b[3]
            let aWord := mload(add(a, 0x60))
            let bWord := mload(add(b, 0x60))
            let sum := add(aWord, bWord)
            mstore(add(c, 0x60), sum)
            // carry = c[3] < a[3]
            carry := lt(sum, aWord)

            // c[2] = a[2] + b[2] + carry
            aWord := mload(add(a, 0x40))
            bWord := mload(add(b, 0x40))
            sum := add(aWord, bWord)
            let cWord := add(sum, carry)
            mstore(add(c, 0x40), cWord)
            // carry = (a[2] + b[2] < a[2]) || (c[2] < a[2] + b[2])
            carry := or(lt(sum, aWord), lt(cWord, sum))

            // c[1] = a[1] + b[1] + carry
            aWord := mload(add(a, 0x20))
            bWord := mload(add(b, 0x20))
            sum := add(aWord, bWord)
            cWord := add(sum, carry)
            mstore(add(c, 0x20), cWord)
            // carry = (a[1] + b[1] < a[1]) || (c[1] < a[1] + b[1])
            carry := or(lt(sum, aWord), lt(cWord, sum))

            // c[0] = a[0] + b[0] + carry
            aWord := mload(a)
            bWord := mload(b)
            sum := add(aWord, bWord)
            cWord := add(sum, carry)
            mstore(c, cWord)
            // carry = (a[0] + b[0] < a[0]) || (c[0] < a[0] + b[0])
            carry := or(lt(sum, aWord), lt(cWord, sum))
        }
    }

    /// @dev Computes a - b, returning the 1024-bit result and the carry bit.
    function _sub(uint256[4] memory a, uint256[4] memory b) 
        internal 
        pure
        returns (uint256[4] memory c, uint256 carry)
    {
        assembly {
            // c[3] = a[3] - b[3]
            let aWord := mload(add(a, 0x60))
            let bWord := mload(add(b, 0x60))
            let diff := sub(aWord, bWord)
            mstore(add(c, 0x60), diff)
            // carry = a[3] < b[3]
            carry := lt(aWord, bWord)

            // c[2] = a[2] - b[2]
            aWord := mload(add(a, 0x40))
            bWord := mload(add(b, 0x40))
            diff := sub(aWord, bWord)
            mstore(add(c, 0x40), sub(diff, carry))
            // carry = (a[2] < b[2]) || (c[2] < carry)
            carry := or(lt(aWord, bWord), lt(diff, carry))

            // c[1] = a[1] - b[1]
            aWord := mload(add(a, 0x20))
            bWord := mload(add(b, 0x20))
            diff := sub(aWord, bWord)
            mstore(add(c, 0x20), sub(diff, carry))
            // carry = (a[1] < b[1]) || (c[1] < carry)
            carry := or(lt(aWord, bWord), lt(diff, carry))

            // c[0] = a[0] - b[0]
            aWord := mload(a)
            bWord := mload(b)
            diff := sub(aWord, bWord)
            mstore(c, sub(diff, carry))
            // carry = (a[0] < b[0]) || (c[0] < carry)
            carry := or(lt(aWord, bWord), lt(diff, carry))
        }
    }

    /// @dev a == b
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

    /// @dev a > b
    function gt(uint256[4] memory a, uint256[4] memory b)
        internal
        pure
        returns (bool)
    {
        return _gt(a, b, false);
    }

    /// @dev a ≥ b
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

    /// @dev a < b
    function lt(uint256[4] memory a, uint256[4] memory b)
        internal
        pure
        returns (bool)
    {
        return _lt(a, b, false);
    }

    /// a ≤ b
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

    /// @dev Computes (a * b) % modulus. Assumes a < modulus and b < modulus.
    ///      Based on the "schoolbook" multiplication algorithm, using the EXPMOD
    ///      precompile to reduce by the modulus.
    function mulMod(uint256[4] memory a, uint256[4] memory b, uint256[4] memory modulus)
        internal
        view
        returns (uint256[4] memory result)
    {
        assembly {
            // Computes x + y and increments the carry value if 
            // x + y overflows.
            function addWithCarry(x, y, carry) -> z, updatedCarry {
                z := add(x, y)
                updatedCarry := add(carry, lt(z, x))
            }

            // Multiplies two 256-bit mumbers to obtain the full 512-bit
            // result. h/t Remco Bloemen for this implementation:
            // https://medium.com/wicketh/mathemagic-full-multiply-27650fec525d
            function mul512(x, y) -> r1, r0 {
                let mm := mulmod(x, y, MAX_UINT)
                r0 := mul(x, y)
                r1 := sub(sub(mm, r0), lt(mm, r0))
            }

            // The implementation roughly follows the schoolbook method:

            //                                         ===a[0]== ===a[1]== ===a[2]== ===a[3]==
            // x                                       ===b[0]== ===b[1]== ===b[2]== ===b[3]==
            // –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
            //                                                             ======a[3]b[3]======
            //                                                   ======a[2]b[3]======
            //                                         ======a[1]b[3]======
            //                               ======a[0]b[3]======
            //                                                   ======a[3]b[2]======
            //                                         ======a[2]b[2]======
            //                               ======a[1]b[2]======
            //                     ======a[0]b[2]======
            //                                         ======a[3]b[1]======
            //                               ======a[2]b[1]======
            //                     ======a[1]b[1]======
            //           ======a[0]b[1]======
            //                               ======a[3]b[0]======
            //                     ======a[2]b[0]======
            //           ======a[1]b[0]======
            // ======a[0]b[0]======
            // –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
            //           |         |         |         |         |         |         |         |
            //           |         |         |         |         |         |         |         |
            //     r0    |    r1   |    r2   |    r3   |    r4   |    r5   |    r6   |    r7   |
            
            // Each a[j]b[k] is computed using mul512, so the result occupies two words.
            // Let a[j]b[k].h and a[j]b[k].l denote the high and low words, respectively.
            
            // Each ri will be computed as the sum of all the words in its column, plus the
            // carry ci from r{i+1}. 
            
            // For example:
            // r7 := a[3]b[3].l
            // r6 := a[3]b[3].h + a[2]b[3].l + a[3]b[2].l
            // c5 := the carry value from the above sum
            // r5 := a[2]b[3].h + a[3]b[2].h + a[1]b[3].l + a[2]b[2].l + a[3]b[1].l + c5
            // c4 :+ the carry value from the above sum
            // ...and so on
            
            let p := mload(0x40)

            // Load all four words of a
            let a0 := mload(a)
            let a1 := mload(add(a, 0x20))
            let a2 := mload(add(a, 0x40))
            let a3 := mload(add(a, 0x60))

            // This is where the words of the multiplication result (before reduction) will go.
            let r0 := 0
            let r1 := 0
            let r2 := 0
            let r3 := 0
            let r4 := 0
            let r5 := 0
            let r6 := 0

            // These will keep track of the carry values for each column.
            let c0 := 0
            let c1 := 0
            let c2 := 0
            let c3 := 0
            let c4 := 0
            let c5 := 0

            let h := 0
            let l := 0

            // b[3]
            let bi := mload(add(b, 0x60))

            // r6 = a[3]b[3].h
            // r7 = a[3]b[3].l
            r6, l := mul512(a3, bi)
            // r7 doesn't get an explicit stack variable, we just mstore it immediately.
            mstore(add(p, 0x140), l)

            // r5 = a[2]b[3].h
            // r6 += a[2]b[3].l
            // c5 = carry from above addition
            r5, l := mul512(a2, bi)
            r6, c5 := addWithCarry(r6, l, 0)
            
            // r4 = a[1]b[3].h
            // r5 += a[1]b[3].l
            // c4 = carry from above addition
            r4, l := mul512(a1, bi)
            r5, c4 := addWithCarry(r5, l, 0)
            
            // r3 = a[0]b[3].h
            // r4 += a[0]b[3].l
            // c3 = carry from above addition
            r3, l := mul512(a0, bi)
            r4, c3 := addWithCarry(r4, l, 0)

            // b[2]
            bi := mload(add(b, 0x40))

            // r6 += a[3]b[2].l
            // c5 += carry from above addition
            // r5 += a[3]b[2].h
            // c4 += carry from above addition
            h, l := mul512(a3, bi)
            r6, c5 := addWithCarry(r6, l, c5)
            r5, c4 := addWithCarry(r5, h, c4)

            // r5 += a[2]b[2].l
            // c4 += carry from above addition
            // r4 += a[2]b[2].h
            // c3 += carry from above addition
            h, l := mul512(a2, bi)
            r5, c4 := addWithCarry(r5, l, c4)
            r4, c3 := addWithCarry(r4, h, c3)

            // r4 += a[1]b[2].l
            // c3 += carry from above addition
            // r3 += a[1]b[2].h
            // c2 += carry from above addition
            h, l := mul512(a1, bi)
            r4, c3 := addWithCarry(r4, l, c3)
            r3, c2 := addWithCarry(r3, h, c2)

            // r3 += a[0]b[2].l
            // c2 += carry from above addition
            // r2 += a[0]b[2].h
            // c1 += carry from above addition
            h, l := mul512(a0, bi)
            r3, c2 := addWithCarry(r3, l, c2)
            r2, c1 := addWithCarry(r2, h, c1)

            // b[1]
            bi := mload(add(b, 0x20))

            // r5 += a[3]b[1].l
            // c4 += carry from above addition
            // r4 += a[3]b[1].h
            // c3 += carry from above addition
            h, l := mul512(a3, bi)
            r5, c4 := addWithCarry(r5, l, c4)
            r4, c3 := addWithCarry(r4, h, c3)

            // r4 += a[2]b[1].l
            // c3 += carry from above addition
            // r3 += a[2]b[1].h
            // c2 += carry from above addition
            h, l := mul512(a2, bi)
            r4, c3 := addWithCarry(r4, l, c3)
            r3, c2 := addWithCarry(r3, h, c2)

            // r3 += a[1]b[1].l
            // c2 += carry from above addition
            // r2 += a[1]b[1].h
            // c1 += carry from above addition
            h, l := mul512(a1, bi)
            r3, c2 := addWithCarry(r3, l, c2)
            r2, c1 := addWithCarry(r2, h, c1)

            // r2 += a[0]b[1].l
            // c1 += carry from above addition
            // r1 += a[0]b[1].h
            // c0 += carry from above addition
            h, l := mul512(a0, bi)
            r2, c1 := addWithCarry(r2, l, c1)
            r1, c0 := addWithCarry(r1, h, c0)

            // b[0]
            bi := mload(b)

            // r4 += a[3]b[0].l
            // c3 += carry from above addition
            // r3 += a[3]b[0].h
            // c2 += carry from above addition
            h, l := mul512(a3, bi)
            r4, c3 := addWithCarry(r4, l, c3)
            r3, c2 := addWithCarry(r3, h, c2)

            // r3 += a[2]b[0].l
            // c2 += carry from above addition
            // r2 += a[2]b[0].h
            // c1 += carry from above addition
            h, l := mul512(a2, bi)
            r3, c2 := addWithCarry(r3, l, c2)
            r2, c1 := addWithCarry(r2, h, c1)

            // r2 += a[1]b[0].l
            // c1 += carry from above addition
            // r1 += a[1]b[0].h
            // c0 += carry from above addition
            h, l := mul512(a1, bi)
            r2, c1 := addWithCarry(r2, l, c1)
            r1, c0 := addWithCarry(r1, h, c0)

            // r1 += a[0]b[0].l
            // c0 += carry from above addition
            // r0 = a[0]b[0].h
            r0, l := mul512(a0, bi)
            r1, c0 := addWithCarry(r1, l, c0)

            // r5 += c5
            // c4 += carry from above addition
            r5 := add(r5, c5)
            c4 := add(c4, lt(r5, c5))

            // r4 += c4
            // c3 += carry from above addition
            r4 := add(r4, c4)
            c3 := add(c3, lt(r4, c4))

            // r3 += c3
            // c2 += carry from above addition
            r3 := add(r3, c3)
            c2 := add(c2, lt(r3, c3))

            // r2 += c2
            // c1 += carry from above addition
            r2 := add(r2, c2)
            c1 := add(c1, lt(r2, c2))

            // r1 += c1
            // c0 += carry from above addition
            r1 := add(r1, c1)
            c0 := add(c0, lt(r1, c1))

            // r0 += c0 (cannot overflow)
            mstore(add(p, 0x60), add(r0, c0))
            
            // Use EXPMOD precompile to compute
            // (r ** 1) % modulus = r % modulus

            // Store parameters for the EXPMOD precompile
            mstore(p, 0x100)               // Length of base (8 * 32 = 256 bytes)
            mstore(add(p, 0x20), 0x20)     // Length of exponent
            mstore(add(p, 0x40), 0x80)     // Length of modulus (4 * 32 = 128 bytes)

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

    /// @dev Computes (a + b) % modulus. Assumes a < modulus and b < modulus.
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

    /// @dev Computes (a - b) % modulus. Assumes a < modulus and b < modulus.
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

    /// @dev Computes (base ** exponent) % modulus
    function expMod(uint256[4] memory base, uint256 exponent, uint256[4] memory modulus)
        internal
        view
        returns (uint256[4] memory result)
    {
        assembly {
            // Get free memory pointer
            let p := mload(0x40)

            // Store parameters for the EXPMOD precompile
            mstore(p, 0x80)                // Length of base (4 * 32 = 128 bytes)
            mstore(add(p, 0x20), 0x20)     // Length of exponent (32 bytes)
            mstore(add(p, 0x40), 0x80)     // Length of modulus (4 * 32 = 128 bytes)

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

    /// @dev Computes (base ** exponent) % modulus
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

            // Store parameters for the EXPMOD precompile
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

    /// @dev Converts an element `x` of the RSA group Z_N to its "coset 
    ///      representative", defined to be min(x mod N, -x mod N). This ensures
    ///      that the low-order assumption is not trivially false, see Section 6:
    ///      http://crypto.stanford.edu/~dabo/papers/VDFsurvey.pdf
    function normalize(
        uint256[4] memory x,
        uint256[4] memory modulus
    )
        internal
        pure
        returns (uint256[4] memory normalized)
    {
        uint256[4] memory negX = modulus.sub(x);
        if (negX.lt(x)) {
            return negX;
        }
        return x;
    }
}
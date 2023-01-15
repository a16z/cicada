pragma solidity ^0.8;

library LibBigMath {
    using LibBigMath for *;

    error Overflow(BigNumber2048 a, BigNumber2048 b);
    error Underflow(BigNumber2048 a, BigNumber2048 b);

    struct BigNumber2048 {
        uint256[8] words;
    }
    
    function toBigNumber2048(uint256 x)
        internal 
        pure 
        returns (BigNumber2048 memory bn) 
    {
        bn = BigNumber2048([uint256(0), 0, 0, 0, 0, 0, 0, x]);
    }

    function add(BigNumber2048 memory a, BigNumber2048 memory b) 
        internal 
        pure
        returns (BigNumber2048 memory c)
    {
        uint256 carry;
        assembly {
            let aPtr := mload(a)
            let bPtr := mload(b)
            let cPtr := mload(c)

            let aWord := mload(add(aPtr, 0xe0))
            let bWord := mload(add(bPtr, 0xe0))
            let sum := add(aWord, bWord)
            mstore(add(cPtr, 0xe0), sum)
            carry := lt(sum, aWord)

            aWord := mload(add(aPtr, 0xc0))
            bWord := mload(add(bPtr, 0xc0))
            sum := add(aWord, bWord)
            let cWord := add(sum, carry)
            mstore(add(cPtr, 0xc0), cWord)
            carry := or(lt(sum, aWord), lt(cWord, carry))

            aWord := mload(add(aPtr, 0xa0))
            bWord := mload(add(bPtr, 0xa0))
            sum := add(aWord, bWord)
            cWord := add(sum, carry)
            mstore(add(cPtr, 0xa0), cWord)
            carry := or(lt(sum, aWord), lt(cWord, sum))

            aWord := mload(add(aPtr, 0x80))
            bWord := mload(add(bPtr, 0x80))
            sum := add(aWord, bWord)
            cWord := add(sum, carry)
            mstore(add(cPtr, 0x80), cWord)
            carry := or(lt(sum, aWord), lt(cWord, sum))

            aWord := mload(add(aPtr, 0x60))
            bWord := mload(add(bPtr, 0x60))
            sum := add(aWord, bWord)
            cWord := add(sum, carry)
            mstore(add(cPtr, 0x60), cWord)
            carry := or(lt(sum, aWord), lt(cWord, sum))

            aWord := mload(add(aPtr, 0x40))
            bWord := mload(add(bPtr, 0x40))
            sum := add(aWord, bWord)
            cWord := add(sum, carry)
            mstore(add(cPtr, 0x40), cWord)
            carry := or(lt(sum, aWord), lt(cWord, sum))

            aWord := mload(add(aPtr, 0x20))
            bWord := mload(add(bPtr, 0x20))
            sum := add(aWord, bWord)
            cWord := add(sum, carry)
            mstore(add(cPtr, 0x20), cWord)
            carry := or(lt(sum, aWord), lt(cWord, sum))

            aWord := mload(aPtr)
            bWord := mload(bPtr)
            sum := add(aWord, bWord)
            cWord := add(sum, carry)
            mstore(cPtr, cWord)
            carry := or(lt(sum, aWord), lt(cWord, sum))
        }
        if (carry != 0) {
            revert Overflow(a, b);
        }
    }

    function sub(BigNumber2048 memory a, BigNumber2048 memory b) 
        internal 
        pure
        returns (BigNumber2048 memory c)
    {
        unchecked {
            c.words[7] = a.words[7] - b.words[7];
            uint256 carry = a.words[7] < b.words[7] ? 1 : 0;
            c.words[6] = a.words[6] - b.words[6] - carry;
            carry = ((a.words[6] < b.words[6]) || (a.words[6] == b.words[6] && carry == 1)) ? 1 : 0;
            c.words[5] = a.words[5] - b.words[5] - carry;
            carry = ((a.words[5] < b.words[5]) || (a.words[5] == b.words[5] && carry == 1)) ? 1 : 0;
            c.words[4] = a.words[4] - b.words[4] - carry;
            carry = ((a.words[4] < b.words[4]) || (a.words[4] == b.words[4] && carry == 1)) ? 1 : 0;
            c.words[3] = a.words[3] - b.words[3] - carry;
            carry = ((a.words[3] < b.words[3]) || (a.words[3] == b.words[3] && carry == 1)) ? 1 : 0;
            c.words[2] = a.words[2] - b.words[2] - carry;
            carry = ((a.words[2] < b.words[2]) || (a.words[2] == b.words[2] && carry == 1)) ? 1 : 0;
            c.words[1] = a.words[1] - b.words[1] - carry;
            carry = ((a.words[1] < b.words[1]) || (a.words[1] == b.words[1] && carry == 1)) ? 1 : 0;
            c.words[0] = a.words[0] - b.words[0] - carry;
            carry = ((a.words[0] < b.words[0]) || (a.words[0] == b.words[0] && carry == 1)) ? 1 : 0;
            if (carry != 0) {
                revert Underflow(a, b);
            }
        }
    }

    function eq(BigNumber2048 memory a, BigNumber2048 memory b)
        internal
        pure
        returns (bool)
    {
        return
            a.words[0] == b.words[0] &&
            a.words[1] == b.words[1] &&
            a.words[2] == b.words[2] &&
            a.words[3] == b.words[3] &&
            a.words[4] == b.words[4] &&
            a.words[5] == b.words[5] &&
            a.words[6] == b.words[6] &&
            a.words[7] == b.words[7];
    }

    function gt(BigNumber2048 memory a, BigNumber2048 memory b)
        internal
        pure
        returns (bool)
    {
        return _gt(a, b, false);
    }

    function gte(BigNumber2048 memory a, BigNumber2048 memory b)
        internal
        pure
        returns (bool)
    {
        return _gt(a, b, true);
    }

    function _gt(
        BigNumber2048 memory a, 
        BigNumber2048 memory b, 
        bool trueIfEqual
    )
        private
        pure
        returns (bool)
    {
        if (a.words[0] < b.words[0]) {
            return false;
        } else if (a.words[0] > b.words[0]) {
            return true;
        }
        if (a.words[1] < b.words[1]) {
            return false;
        } else if (a.words[1] > b.words[1]) {
            return true;
        }
        if (a.words[2] < b.words[2]) {
            return false;
        } else if (a.words[2] > b.words[2]) {
            return true;
        }
        if (a.words[3] < b.words[3]) {
            return false;
        } else if (a.words[3] > b.words[3]) {
            return true;
        }
        if (a.words[4] < b.words[4]) {
            return false;
        } else if (a.words[4] > b.words[4]) {
            return true;
        }
        if (a.words[5] < b.words[5]) {
            return false;
        } else if (a.words[5] > b.words[5]) {
            return true;
        }
        if (a.words[6] < b.words[6]) {
            return false;
        } else if (a.words[6] > b.words[6]) {
            return true;
        }
        if (a.words[7] < b.words[7]) {
            return false;
        }
        return trueIfEqual || (a.words[7] > b.words[7]);
    }

    function lt(BigNumber2048 memory a, BigNumber2048 memory b)
        internal
        pure
        returns (bool)
    {
        return _lt(a, b, false);
    }

    function lte(BigNumber2048 memory a, BigNumber2048 memory b)
        internal
        pure
        returns (bool)
    {
        return _lt(a, b, true);
    }

    function _lt(
        BigNumber2048 memory a, 
        BigNumber2048 memory b, 
        bool trueIfEqual
    )
        private
        pure
        returns (bool)
    {
        if (a.words[0] > b.words[0]) {
            return false;
        } else if (a.words[0] < b.words[0]) {
            return true;
        }
        if (a.words[1] > b.words[1]) {
            return false;
        } else if (a.words[1] < b.words[1]) {
            return true;
        }
        if (a.words[2] > b.words[2]) {
            return false;
        } else if (a.words[2] < b.words[2]) {
            return true;
        }
        if (a.words[3] > b.words[3]) {
            return false;
        } else if (a.words[3] < b.words[3]) {
            return true;
        }
        if (a.words[4] > b.words[4]) {
            return false;
        } else if (a.words[4] < b.words[4]) {
            return true;
        }
        if (a.words[5] > b.words[5]) {
            return false;
        } else if (a.words[5] < b.words[5]) {
            return true;
        }
        if (a.words[6] > b.words[6]) {
            return false;
        } else if (a.words[6] < b.words[6]) {
            return true;
        }
        if (a.words[7] > b.words[7]) {
            return false;
        } 
        return trueIfEqual || a.words[7] < b.words[7];
    }

    function mulMod(BigNumber2048 memory a, BigNumber2048 memory b, BigNumber2048 memory modulus)
        internal
        view
        returns (BigNumber2048 memory result)
    {
        BigNumber2048 memory sumSquared = a.add(b).expMod(2, modulus);
        BigNumber2048 memory differenceSquared = a.subMod(b, modulus).expMod(2, modulus);
        // Returns (a+b)^2 - (a-b)^2 = 4ab
        return sumSquared.subMod(differenceSquared, modulus);
    }

    function addMod(BigNumber2048 memory a, BigNumber2048 memory b, BigNumber2048 memory modulus)
        internal
        pure
        returns (BigNumber2048 memory result)
    {
        result = a.add(b);
        if (result.gte(modulus)) {
            result = result.sub(modulus);
        }
    }

    function subMod(BigNumber2048 memory a, BigNumber2048 memory b, BigNumber2048 memory modulus)
        internal
        pure
        returns (BigNumber2048 memory result)
    {
        if (a.gte(b)) {
            return a.sub(b);
        } else {
            return modulus.sub(b.sub(a));
        }
    }

    function expMod(BigNumber2048 memory base, uint256 exponent, BigNumber2048 memory modulus)
        internal
        view
        returns (BigNumber2048 memory result)
    {
        if (exponent == 0) {
            return uint256(1).toBigNumber2048();
        }

        assembly {
            // Get free memory pointer
            let p := mload(0x40)

            // Store parameters for the Expmod (0x05) precompile
            mstore(p, 0x100)               // Length of base (8 * 32 = 256 bytes)
            mstore(add(p, 0x20), 0x20)     // Length of exponent
            mstore(add(p, 0x40), 0x100)    // Length of modulus (8 * 32 = 256 bytes)

            // Use Identity (0x04) precompile to memcpy the base
            if iszero(staticcall(gas(), 0x04, mload(base), 0x100, add(p, 0x60), 0x100)) {
                revert(0, 0)
            }
            // Store the exponent
            mstore(add(p, 0x160), exponent)
            // Use Identity (0x04) precompile to memcpy the modulus
            if iszero(staticcall(gas(), 0x04, mload(modulus), 0x100, add(p, 0x180), 0x100)) {
                revert(0, 0)
            }
            // Call 0x05 (EXPMOD) precompile
            if iszero(staticcall(gas(), 0x05, p, 0x280, mload(result), 0x100)) {
                revert(0, 0)
            }

            // Update free memory pointer
            mstore(0x40, add(p, 0x280))
        }
    }
}
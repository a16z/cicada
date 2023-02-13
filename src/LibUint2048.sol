pragma solidity ^0.8;

library LibUint2048 {
    using LibUint2048 for *;

    error Overflow(uint256[8] a, uint256[8] b);
    error Underflow(uint256[8] a, uint256[8] b);

    function toUint2048(uint256 x)
        internal 
        pure 
        returns (uint256[8] memory bn) 
    {
        bn[7] = x;
    }

    function add(uint256[8] memory a, uint256[8] memory b) 
        internal 
        pure
        returns (uint256[8] memory c)
    {
        uint256 carry;
        (c, carry) = _add(a, b);
        if (carry != 0) {
            revert Overflow(a, b);
        }
    }

    function sub(uint256[8] memory a, uint256[8] memory b) 
        internal 
        pure
        returns (uint256[8] memory c)
    {
        uint256 carry;
        (c, carry) = _sub(a, b);
        if (carry != 0) {
            revert Underflow(a, b);
        }
    }

    function _add(uint256[8] memory a, uint256[8] memory b) 
        private 
        pure
        returns (uint256[8] memory c, uint256 carry)
    {
        assembly {
            let aWord := mload(add(a, 0xe0))
            let bWord := mload(add(b, 0xe0))
            let sum := add(aWord, bWord)
            mstore(add(c, 0xe0), sum)
            carry := lt(sum, aWord)

            aWord := mload(add(a, 0xc0))
            bWord := mload(add(b, 0xc0))
            sum := add(aWord, bWord)
            let cWord := add(sum, carry)
            mstore(add(c, 0xc0), cWord)
            carry := or(lt(sum, aWord), lt(cWord, carry))

            aWord := mload(add(a, 0xa0))
            bWord := mload(add(b, 0xa0))
            sum := add(aWord, bWord)
            cWord := add(sum, carry)
            mstore(add(c, 0xa0), cWord)
            carry := or(lt(sum, aWord), lt(cWord, sum))

            aWord := mload(add(a, 0x80))
            bWord := mload(add(b, 0x80))
            sum := add(aWord, bWord)
            cWord := add(sum, carry)
            mstore(add(c, 0x80), cWord)
            carry := or(lt(sum, aWord), lt(cWord, sum))

            aWord := mload(add(a, 0x60))
            bWord := mload(add(b, 0x60))
            sum := add(aWord, bWord)
            cWord := add(sum, carry)
            mstore(add(c, 0x60), cWord)
            carry := or(lt(sum, aWord), lt(cWord, sum))

            aWord := mload(add(a, 0x40))
            bWord := mload(add(b, 0x40))
            sum := add(aWord, bWord)
            cWord := add(sum, carry)
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

    function _sub(uint256[8] memory a, uint256[8] memory b) 
        private 
        pure
        returns (uint256[8] memory c, uint256 carry)
    {
        assembly {
            let aWord := mload(add(a, 0xe0))
            let bWord := mload(add(b, 0xe0))
            let diff := sub(aWord, bWord)
            mstore(add(c, 0xe0), diff)
            carry := lt(aWord, bWord)

            aWord := mload(add(a, 0xc0))
            bWord := mload(add(b, 0xc0))
            diff := sub(aWord, bWord)
            mstore(add(c, 0xc0), sub(diff, carry))
            carry := or(lt(aWord, bWord), lt(diff, carry))

            aWord := mload(add(a, 0xa0))
            bWord := mload(add(b, 0xa0))
            diff := sub(aWord, bWord)
            mstore(add(c, 0xa0), sub(diff, carry))
            carry := or(lt(aWord, bWord), lt(diff, carry))

            aWord := mload(add(a, 0x80))
            bWord := mload(add(b, 0x80))
            diff := sub(aWord, bWord)
            mstore(add(c, 0x80), sub(diff, carry))
            carry := or(lt(aWord, bWord), lt(diff, carry))

            aWord := mload(add(a, 0x60))
            bWord := mload(add(b, 0x60))
            diff := sub(aWord, bWord)
            mstore(add(c, 0x60), sub(diff, carry))
            carry := or(lt(aWord, bWord), lt(diff, carry))

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

    function eq(uint256[8] memory a, uint256[8] memory b)
        internal
        pure
        returns (bool)
    {
        return
            a[0] == b[0] &&
            a[1] == b[1] &&
            a[2] == b[2] &&
            a[3] == b[3] &&
            a[4] == b[4] &&
            a[5] == b[5] &&
            a[6] == b[6] &&
            a[7] == b[7];
    }

    function gt(uint256[8] memory a, uint256[8] memory b)
        internal
        pure
        returns (bool)
    {
        return _gt(a, b, false);
    }

    function gte(uint256[8] memory a, uint256[8] memory b)
        internal
        pure
        returns (bool)
    {
        return _gt(a, b, true);
    }

    function _gt(
        uint256[8] memory a, 
        uint256[8] memory b, 
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
        } else if (a[3] > b[3]) {
            return true;
        }
        if (a[4] < b[4]) {
            return false;
        } else if (a[4] > b[4]) {
            return true;
        }
        if (a[5] < b[5]) {
            return false;
        } else if (a[5] > b[5]) {
            return true;
        }
        if (a[6] < b[6]) {
            return false;
        } else if (a[6] > b[6]) {
            return true;
        }
        if (a[7] < b[7]) {
            return false;
        }
        return trueIfEqual || a[7] > b[7];
    }

    function lt(uint256[8] memory a, uint256[8] memory b)
        internal
        pure
        returns (bool)
    {
        return _lt(a, b, false);
    }

    function lte(uint256[8] memory a, uint256[8] memory b)
        internal
        pure
        returns (bool)
    {
        return _lt(a, b, true);
    }

    function _lt(
        uint256[8] memory a, 
        uint256[8] memory b, 
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
        } else if (a[3] < b[3]) {
            return true;
        }
        if (a[4] > b[4]) {
            return false;
        } else if (a[4] < b[4]) {
            return true;
        }
        if (a[5] > b[5]) {
            return false;
        } else if (a[5] < b[5]) {
            return true;
        }
        if (a[6] > b[6]) {
            return false;
        } else if (a[6] < b[6]) {
            return true;
        }
        if (a[7] > b[7]) {
            return false;
        } 
        return trueIfEqual || a[7] < b[7];
    }

    function mulMod(uint256[8] memory a, uint256[8] memory b, uint256[8] memory modulus)
        internal
        view
        returns (uint256[8] memory result)
    {
        uint256[8] memory sumSquared = a.addMod(b, modulus).expMod(2, modulus);
        uint256[8] memory differenceSquared = a.subMod(b, modulus).expMod(2, modulus);
        // Returns (a+b)^2 - (a-b)^2 = 4ab
        return sumSquared.subMod(differenceSquared, modulus);
    }

    function addMod(uint256[8] memory a, uint256[8] memory b, uint256[8] memory modulus)
        internal
        pure
        returns (uint256[8] memory result)
    {
        uint256 carry;
        (result, carry) = _add(a, b);
        if (carry == 1 || result.gte(modulus)) {
            (result, ) = _sub(result, modulus);
        }
    }

    function subMod(uint256[8] memory a, uint256[8] memory b, uint256[8] memory modulus)
        internal
        pure
        returns (uint256[8] memory result)
    {
        if (a.gte(b)) {
            return a.sub(b);
        } else {
            return modulus.sub(b.sub(a));
        }
    }

    function expMod(uint256[8] memory base, uint256 exponent, uint256[8] memory modulus)
        internal
        view
        returns (uint256[8] memory result)
    {
        if (exponent == 0) {
            return uint256(1).toUint2048();
        }

        assembly {
            // Get free memory pointer
            let p := mload(0x40)

            // Store parameters for the Expmod (0x05) precompile
            mstore(p, 0x100)               // Length of base (8 * 32 = 256 bytes)
            mstore(add(p, 0x20), 0x20)     // Length of exponent
            mstore(add(p, 0x40), 0x100)    // Length of modulus (8 * 32 = 256 bytes)

            // Use Identity (0x04) precompile to memcpy the base
            if iszero(staticcall(gas(), 0x04, base, 0x100, add(p, 0x60), 0x100)) {
                revert(0, 0)
            }
            // Store the exponent
            mstore(add(p, 0x160), exponent)
            // Use Identity (0x04) precompile to memcpy the modulus
            if iszero(staticcall(gas(), 0x04, modulus, 0x100, add(p, 0x180), 0x100)) {
                revert(0, 0)
            }
            // Call 0x05 (EXPMOD) precompile
            if iszero(staticcall(gas(), 0x05, p, 0x280, result, 0x100)) {
                revert(0, 0)
            }

            // Update free memory pointer
            mstore(0x40, add(p, 0x280))
        }
    }

    function expMod(
        uint256[8] memory base, 
        uint256[8] memory exponent, 
        uint256[8] memory modulus
    )
        internal
        view
        returns (uint256[8] memory result)
    {
        assembly {
            // Get free memory pointer
            let p := mload(0x40)

            // Store parameters for the Expmod (0x05) precompile
            mstore(p, 0x100)               // Length of base (8 * 32 = 256 bytes)
            mstore(add(p, 0x20), 0x100)    // Length of exponent (8 * 32 = 256 bytes)
            mstore(add(p, 0x40), 0x100)    // Length of modulus (8 * 32 = 512 bytes)

            // Use Identity (0x04) precompile to memcpy the base
            if iszero(staticcall(gas(), 0x04, base, 0x100, add(p, 0x60), 0x100)) {
                revert(0, 0)
            }
            // Use Identity (0x04) precompile to memcpy the exponent
            if iszero(staticcall(gas(), 0x04, exponent, 0x100, add(p, 0x160), 0x100)) {
                revert(0, 0)
            }
            // Use Identity (0x04) precompile to memcpy the modulus
            if iszero(staticcall(gas(), 0x04, modulus, 0x100, add(p, 0x260), 0x100)) {
                revert(0, 0)
            }
            // Call 0x05 (EXPMOD) precompile
            if iszero(staticcall(gas(), 0x05, p, 0x360, result, 0x100)) {
                revert(0, 0)
            }

            // Update free memory pointer
            mstore(0x40, add(p, 0x560))
        }
    }

    function expMod(
        uint256[8] memory base, 
        uint256[8] memory exponent, 
        uint256[16] memory modulus
    )
        internal
        view
        returns (uint256[16] memory result)
    {
        assembly {
            // Get free memory pointer
            let p := mload(0x40)

            // Store parameters for the Expmod (0x05) precompile
            mstore(p, 0x100)               // Length of base (8 * 32 = 256 bytes)
            mstore(add(p, 0x20), 0x100)    // Length of exponent (8 * 32 = 256 bytes)
            mstore(add(p, 0x40), 0x200)    // Length of modulus (16 * 32 = 512 bytes)

            // Use Identity (0x04) precompile to memcpy the base
            if iszero(staticcall(gas(), 0x04, base, 0x100, add(p, 0x60), 0x100)) {
                revert(0, 0)
            }
            // Use Identity (0x04) precompile to memcpy the exponent
            if iszero(staticcall(gas(), 0x04, exponent, 0x100, add(p, 0x160), 0x100)) {
                revert(0, 0)
            }
            // Use Identity (0x04) precompile to memcpy the modulus
            if iszero(staticcall(gas(), 0x04, modulus, 0x200, add(p, 0x260), 0x200)) {
                revert(0, 0)
            }
            // Call 0x05 (EXPMOD) precompile
            if iszero(staticcall(gas(), 0x05, p, 0x460, result, 0x200)) {
                revert(0, 0)
            }

            // Update free memory pointer
            mstore(0x40, add(p, 0x660))
        }
    }

}
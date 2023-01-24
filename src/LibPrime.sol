pragma solidity ^0.8;

library LibPrime {
            
    uint256 constant MILLER_RABIN_ITERATIONS = 28;

    // Use Miller-Rabin test to probabilistically check whether n>3 is prime.
    // Based on Dankrad Feist's implementation:
    // https://github.com/dankrad/rsa-bounty/blob/master/contract/rsa_bounty.sol
    function millerRabin(uint256 n) internal view returns (bool) {
        unchecked {
            if (n & 1 == 0) {
                return false;
            }
            uint256 d = n - 1;
            uint256 r = 0;

            assembly {
                for {} iszero(and(d, 1)) {} {
                    d := shr(1, d)
                    r := add(r, 1)
                }
            }

            uint256 m = n - 3;
            uint256 memPtr;
            uint256 basePtr;
            assembly { 
                mstore(0, n)
                mstore(0x20, blockhash(sub(number(), 1)))
                // Get free memory pointer
                memPtr := mload(0x40)
                // Store parameters for the Expmod (0x05) precompile
                mstore(memPtr, 0x20)             // Length of Base
                mstore(add(memPtr, 0x20), 0x20)  // Length of Exponent
                mstore(add(memPtr, 0x40), 0x20)  // Length of Modulus
                basePtr := add(memPtr, 0x60)     // Base
                mstore(add(memPtr, 0x80), d)     // Exponent
                mstore(add(memPtr, 0xa0), n)     // Modulus
            }
            for (uint256 i = 0; i != MILLER_RABIN_ITERATIONS; ++i) {
                uint256 x;
                assembly {
                    // pick a pseudorandom integer a in the range [2, n − 2]
                    mstore8(0x20, i)
                    let a := add(mod(keccak256(0, 0x40), m), 2)
                    mstore(basePtr, a)
                    // Call 0x05 (EXPMOD) precompile
                    if iszero(staticcall(gas(), 0x05, memPtr, 0xc0, basePtr, 0x20)) {
                        revert(0, 0)
                    }
                    x := mload(basePtr)
                }
                if (x == 1 || x == n - 1) {
                    continue;
                }
                bool check_passed = false;
                for (uint256 j = 1; j != r; ++j) {
                    x = mulmod(x, x, n);
                    if (x == n - 1) {
                        check_passed = true;
                        break;
                    }
                }
                if (!check_passed) {
                    assembly {
                        // Update free memory pointer
                        mstore(0x40, add(memPtr, 0xc0))
                    }
                    return false;
                }
            }
            assembly {
                // Update free memory pointer
                mstore(0x40, add(memPtr, 0xc0))
            }
            return true;
        }
    }
}
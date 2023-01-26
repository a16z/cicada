pragma solidity ^0.8;


library LibPrime {
    using LibPrime for uint256;

    function bailliePSW(uint256 n)
        internal
        view
    {
        // Miller-Rabin with x=2
        // Lucas
    }

    function lucas(uint256 n)
        internal
        view
        returns (bool)
    {
        uint256 p = 3;
        uint256 d;
        unchecked {
            while (true) {
                d = p * p - 4;
                int256 j = jacobi(d, n);
                if (j == -1) {
                    break;
                }
                if (j == 0) {
                    return n == p + 2;
                }
                // Omit square check
                p++;
            }
        }

        uint256 s = n + 1;
        uint256 r = trailingZeros(s);
        s >>= r;
        uint256 nm2;
        unchecked { nm2 = n - 2; }

        uint256 vk = 2;
        uint256 vk1 = p;
        for (uint256 bit = 1 << bitLen(s); bit != 0; bit >>= 1) {
            if (s & bit != 0) {
                // vk = (vk * vk1 + n - p) % n;
                // vk1 = (vk1 * vk1 + nm2) % n;
                assembly {
                    vk := mulmod(vk, vk1, n)
                    vk := addmod(vk, sub(n, p), n)
                    vk1 := mulmod(vk1, vk1, n)
                    vk1 := addmod(vk1, nm2, n)
                }
            } else {
                // vk1 = (vk * vk1 + n - p) % n;
                // vk = (vk * vk + nm2) % n;
                assembly {
                    vk1 := mulmod(vk, vk1, n)
                    vk1 := addmod(vk1, sub(n, p), n)
                    vk := mulmod(vk, vk, n)
                    vk := addmod(vk, nm2, n)
                }
            }
        }

        if (vk == 2 || vk == nm2) {
            uint256 t1;
            uint256 t2;
            assembly {
                t1 := mulmod(vk, p, n)
                t2 := mulmod(vk1, 2, n)
            }
            if (t1 == t2) {
                return true;
            }
        }

        uint256 rLess1;
        unchecked { rLess1 = r - 1; }
        for (uint256 t = 0; t != rLess1; ++t) {
            if (vk == 0) {
                return true;
            }
            if (vk == 2) {
                return false;
            }
            // vk = (vk * vk + nm2) % n;
            assembly {
                vk := mulmod(vk, vk, n)
                vk := addmod(vk, nm2, n)
            }
        }
        return false;
    }

    bytes32 constant HIGHEST_BIT_DE_BRUIJN_TABLE = 0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f;
    uint256 constant HIGHEST_BIT_DE_BRUIJN_SEQUENCE = 130329821;
    function bitLen(uint256 v)
        private
        pure
        returns (uint256 r)
    {
        unchecked {
            assembly {
                let f := shl(7, gt(v, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                r := or(r, f)
                v := shr(f, v)

                f := shl(6, gt(v, 0xFFFFFFFFFFFFFFFF))
                r := or(r, f)
                v := shr(f, v)

                f := shl(5, gt(v, 0xFFFFFFFF))
                r := or(r, f)
                v := shr(f, v)

                v := or(v, shr(1, v))
                v := or(v, shr(2, v))
                v := or(v, shr(4, v))
                v := or(v, shr(8, v))
                v := or(v, shr(16, v))
            }
            uint256 index = uint32(v * HIGHEST_BIT_DE_BRUIJN_SEQUENCE) >> 27;
            assembly {
                r := add(r, byte(index, HIGHEST_BIT_DE_BRUIJN_TABLE))
            }
        }
    }

    bytes32 constant LOWEST_BIT_DE_BRUIJN_TABLE = 0x00011c021d0e18031e16140f191104081f1b0d17151310071a0c12060b050a09;
    uint256 constant LOWEST_BIT_DE_BRUIJN_SEQUENCE = 125613361;
    function trailingZeros(uint256 v)
        private
        pure
        returns (uint256 r)
    {
        unchecked {
            if (v & 0xffffffffffffffffffffffffffffffff == 0) {
                r = 128;
                v >>= 128;
            }
            if (v & 0xffffffffffffffff == 0) {
                r += 64;
                v >>= 64;
            }
            if (v & 0xffffffff == 0) {
                r += 32;
                v >>= 32;
            }
            int256 negV = -int256(v);
            uint256 index = uint32((v & uint256(negV)) * LOWEST_BIT_DE_BRUIJN_SEQUENCE) >> 27;
            assembly {
                r := add(r, byte(index, LOWEST_BIT_DE_BRUIJN_TABLE))
            }
        }
    }

    function jacobi(uint256 d, uint256 n)
        internal
        pure
        returns (int256 j)
    {
        // require(n & 1 == 1);
        unchecked {
            d = d % n;
            j = 1;
            uint256 r;
            while (d != 0) {
                while (d & 1 == 0) {
                    d = d >> 1;
                    r = n & 7; // n % 8
                    if (r == 3 || r == 5) {
                        j = -j;
                    }
                }
                r = n;
                n = d;
                d = r;
                if (d & 3 == 3 && n & 3 == 3) { // d % 4 == 3 && n % 4 == 3
                    j = -j;
                }
                d = d % n;
            }
            if (n == 1) {
                return j;
            }
            return 0;
        }
    }
    
    error EvenNumber(uint256 n);
    error InvalidFactorization(uint256 expectedProduct, uint256 actualProduct);
    error NotCoprime(uint256 a, uint256 b);
    error TooBigForBaseCase(uint256 n);
    error PocklingtonCheck1Failed(uint256 n, uint256 b);
    error PocklingtonCheck2Failed(uint256 n, uint256 b, uint256 p);
    error InvalidFR(uint256 F, uint256 R);
    error NotPrime(uint256 n);
    error MillerRabinCheckFailed();

    // 33542727543779740430490605455518991165603357328065026694872905989203690834798
    uint256 constant PRIMES_BIT_MASK = 
        (1 << (3 >> 1))   | (1 << (5 >> 1))   | (1 << (7 >> 1))   | (1 << (11 >> 1))  |
        (1 << (13 >> 1))  | (1 << (17 >> 1))  | (1 << (19 >> 1))  | (1 << (23 >> 1))  |
        (1 << (29 >> 1))  | (1 << (31 >> 1))  | (1 << (37 >> 1))  | (1 << (41 >> 1))  |
        (1 << (43 >> 1))  | (1 << (47 >> 1))  | (1 << (53 >> 1))  | (1 << (59 >> 1))  |
        (1 << (61 >> 1))  | (1 << (67 >> 1))  | (1 << (71 >> 1))  | (1 << (73 >> 1))  |
        (1 << (79 >> 1))  | (1 << (83 >> 1))  | (1 << (89 >> 1))  | (1 << (97 >> 1))  |
        (1 << (101 >> 1)) | (1 << (103 >> 1)) | (1 << (107 >> 1)) | (1 << (109 >> 1)) |
        (1 << (113 >> 1)) | (1 << (127 >> 1)) | (1 << (131 >> 1)) | (1 << (137 >> 1)) |
        (1 << (139 >> 1)) | (1 << (149 >> 1)) | (1 << (151 >> 1)) | (1 << (157 >> 1)) |
        (1 << (163 >> 1)) | (1 << (167 >> 1)) | (1 << (173 >> 1)) | (1 << (179 >> 1)) |
        (1 << (181 >> 1)) | (1 << (191 >> 1)) | (1 << (193 >> 1)) | (1 << (197 >> 1)) |
        (1 << (199 >> 1)) | (1 << (211 >> 1)) | (1 << (223 >> 1)) | (1 << (227 >> 1)) |
        (1 << (229 >> 1)) | (1 << (233 >> 1)) | (1 << (239 >> 1)) | (1 << (241 >> 1)) |
        (1 << (251 >> 1)) | (1 << (257 >> 1)) | (1 << (263 >> 1)) | (1 << (269 >> 1)) |
        (1 << (271 >> 1)) | (1 << (277 >> 1)) | (1 << (281 >> 1)) | (1 << (283 >> 1)) |
        (1 << (293 >> 1)) | (1 << (307 >> 1)) | (1 << (311 >> 1)) | (1 << (313 >> 1)) |
        (1 << (317 >> 1)) | (1 << (331 >> 1)) | (1 << (337 >> 1)) | (1 << (347 >> 1)) |
        (1 << (349 >> 1)) | (1 << (353 >> 1)) | (1 << (359 >> 1)) | (1 << (367 >> 1)) |
        (1 << (373 >> 1)) | (1 << (379 >> 1)) | (1 << (383 >> 1)) | (1 << (389 >> 1)) |
        (1 << (397 >> 1)) | (1 << (401 >> 1)) | (1 << (409 >> 1)) | (1 << (419 >> 1)) |
        (1 << (421 >> 1)) | (1 << (431 >> 1)) | (1 << (433 >> 1)) | (1 << (439 >> 1)) |
        (1 << (443 >> 1)) | (1 << (449 >> 1)) | (1 << (457 >> 1)) | (1 << (461 >> 1)) |
        (1 << (463 >> 1)) | (1 << (467 >> 1)) | (1 << (479 >> 1)) | (1 << (487 >> 1)) |
        (1 << (491 >> 1)) | (1 << (499 >> 1)) | (1 << (503 >> 1)) | (1 << (509 >> 1));

    struct PocklingtonNums {
        uint256 p;
        uint256 a;
        uint256 b;
    }

    struct PocklingtonStep {
        uint256 F;
        uint256 R;
        PocklingtonNums[] nums;
    }

    function pocklington(uint256 n, PocklingtonStep[] memory certificate) 
        internal 
        view 
    {
        if (n & 1 == 0) {
            revert EvenNumber(n);
        }
        uint256 numSteps = certificate.length;
        if (numSteps == 0) {
            if (n > 512) {
                revert TooBigForBaseCase(n);
            }
            if ((1 << (n >> 1)) & PRIMES_BIT_MASK == 0) {
                revert NotPrime(n);
            }
            return;
        }

        if (n - 1 != certificate[0].F * certificate[0].R) {
            revert InvalidFactorization(
                n - 1, 
                certificate[0].F * certificate[0].R
            );
        }

        assembly {
            // Load free memory pointer
            let p := mload(0x40)
            // Store parameters for the Expmod (0x05) precompile
            mstore(p, 0x20)                  // Length of base 
            mstore(add(p, 0x20), 0x20)       // Length of exponent
            mstore(add(p, 0x40), 0x20)       // Length of modulus 
        }

        uint256 k = 0;
        for (uint256 j = 0; j != numSteps; ) {
            PocklingtonStep memory step = certificate[j];
            unchecked { j++; }

            uint256 F = step.F;
            uint256 R = step.R;
            if (R >= F) {
                revert InvalidFR(F, R);
            }
            if (!coprime(F, R)) {
                revert NotCoprime(F, R);
            }

            uint256 FR;
            unchecked {
                FR = F * R;
                n = FR + 1;
            }

            uint256 prod = 1;
            uint256 numFactors = step.nums.length;
            for (uint256 i = 0; i != numFactors; ) {
                uint256 p = step.nums[i].p;
                uint256 a = step.nums[i].a;
                uint256 b = step.nums[i].b;
                unchecked { i++; }
                if (a == 1) {
                    prod *= p;
                } else {
                    prod *= p ** a;
                }

                if (expMod(b, FR, n) != 1) {
                    revert PocklingtonCheck1Failed(n, b);
                }
                uint256 exponent;
                assembly {
                    exponent := div(FR, p)
                }
                if (!coprime(n, expMod(b, exponent, n) - 1)) {
                    revert PocklingtonCheck2Failed(n, b, p);
                }

                if (p < 512) {
                    if (p == 2) {
                        continue;
                    } else if (p & 1 == 0) {
                        revert EvenNumber(p);
                    }
                    if ((1 << (p >> 1)) & PRIMES_BIT_MASK == 0) {
                        revert NotPrime(p);
                    } else {
                        continue;
                    }
                }
                if (p & 1 == 0) {
                    revert EvenNumber(p);
                }
                unchecked { k++; }
                if (p - 1 != certificate[k].F * certificate[k].R) {
                    revert InvalidFactorization(
                        p - 1, 
                        certificate[k].F * certificate[k].R
                    );
                }
            }

            if (prod != F) {
                revert InvalidFactorization(F, prod);
            }
        }
        assembly {
            // Update free memory pointer
            mstore(0x40, add(mload(0x40), 0xc0))
        }
    }

    function coprime(uint256 a, uint256 b)
        internal
        pure
        returns (bool result)
    {
        assembly {
            for {} iszero(iszero(b)) {} {
                let tmp := a
                a := b
                b := mod(tmp, b)
            }
            result := eq(a, 1)
        }
    }
            
    uint256 constant MILLER_RABIN_ITERATIONS = 30;

    // Use Miller-Rabin test to probabilistically check whether n>3 is prime.
    // Based on Dankrad Feist's implementation:
    // https://github.com/dankrad/rsa-bounty/blob/master/contract/rsa_bounty.sol
    function millerRabin(uint256 n) internal view {
        unchecked {
            if (n & 1 == 0) {
                revert EvenNumber(n);
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
                    revert MillerRabinCheckFailed();
                }
            }
            assembly {
                // Update free memory pointer
                mstore(0x40, add(memPtr, 0xc0))
            }
        }
    }

    function expMod(uint256 base, uint256 exponent, uint256 modulus)
        private
        view
        returns (uint256 result)
    {
        assembly {
            // Get free memory pointer
            let p := mload(0x40)

            // Store parameters for the Expmod (0x05) precompile
            mstore(add(p, 0x60), base)       // Store the base
            mstore(add(p, 0x80), exponent)   // Store the exponent
            mstore(add(p, 0xa0), modulus)   // Store the modulus
            // Call 0x05 (EXPMOD) precompile
            if iszero(staticcall(gas(), 0x05, p, 0xc0, 0, 0x20)) {
                revert(0, 0)
            }
            result := mload(0)
        }
    }
}
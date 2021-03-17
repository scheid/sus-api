//
//  xoshiro256plus.swift
//  App
//
//  Created by Eischeid, Todd on 1/17/20.
//

import Foundation

// http://xoshiro.di.unimi.it/xoshiro256plus.c

/*  Written in 2018 by David Blackman and Sebastiano Vigna (vigna@acm.org)

To the extent possible under law, the author has dedicated all copyright
and related and neighboring rights to this software to the public domain
worldwide. This software is distributed without any warranty.

See <http://creativecommons.org/publicdomain/zero/1.0/>. */


/* This is xoshiro256+ 1.0, our best and fastest generator for floating-point
   numbers. We suggest to use its upper bits for floating-point
   generation, as it is slightly faster than xoshiro256++/xoshiro256**. It
   passes all tests we are aware of except for the lowest three bits,
   which might fail linearity tests (and just those), so if low linear
   complexity is not considered an issue (as it is usually the case) it
   can be used to generate 64-bit outputs, too.

   We suggest to use a sign test to extract a random Boolean value, and
   right shifts to extract subsets of bits.

   The state must be seeded so that it is not everywhere zero. If you have
   a 64-bit seed, we suggest to seed a splitmix64 generator and use its
   output to fill s. */

/*
static inline uint64_t rotl(const uint64_t x, int k) {
    return (x << k) | (x >> (64 - k));
}


static uint64_t s[4];

uint64_t next(void) {
    const uint64_t result = s[0] + s[3];

    const uint64_t t = s[1] << 17;

    s[2] ^= s[0];
    s[3] ^= s[1];
    s[1] ^= s[2];
    s[0] ^= s[3];

    s[2] ^= t;

    s[3] = rotl(s[3], 45);

    return result;
}
*/

// NOTE: original from here: https://stackoverflow.com/questions/50559229/implementing-the-prng-xoshiro256-in-swift-for-a-rn-in-a-given-range
open class Xshiro256plus {
    
    // seed should be a vector of 4 elements
    var seed: [UInt64]
       
    init(seed: [UInt64]) {
        self.seed = seed
    }

    func rotl(_ x: UInt64, _ k: Int) -> UInt64 {
        return (x << k) | (x >> (64 - k))
    } // This is the rotating function.

    
    
    // This returns the next number in the algorithm while XORing the seed vectors for use in the next call.
    func next() -> Double {
        
        //(note the '&') to tell Swift you want the addition to truncate on overflow.
        //You can read the section on 'Overflow Operators' in Apple's book "The Swift Programming Language"
        let result_plus = self.seed[0] &+ self.seed[3]

        let t = self.seed[1] << 17

        self.seed[2] ^= self.seed[0]
        self.seed[3] ^= self.seed[1]
        self.seed[1] ^= self.seed[2]
        self.seed[0] ^= self.seed[3]

        self.seed[2] ^= t

        self.seed[3] = self.rotl(self.seed[3], 45)

        //  Double has 52 mantissa bits, and the hex value is 2**52 (2**52 = 0x10000000000000 = 4503599627370496).
        // This uses the upper 52 bits of your UInt64 to yield a result in the range [0,1.0) with the highest achievable precision.
        // so, cant divide by UInt64.max, but rather 0x10000000000000
        return Double(result_plus >> 12) / 0x10000000000000
      

    }


    
    
}


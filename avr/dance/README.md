# dance.S -- small, fast, cryptographically secure pseudo random generator
optimized for Microchip AVR (Arduino)

copyright 2023 (C) Arlet Ottens <arlet@c-scape.nl>

The `dance()` function is called with a pointer to a 64 byte
state array, followed by 16 bytes worth of initialization vector
(IV). The IV can be as any combination of `uint8_t`, `uint16_t`,
uint32_t or uint64_t, as long as they add up to exactly 16 bytes.

here's a few examples:

```
void dance( uint8_t state[64], uint64_t IV0, uint64_t IV1 )

void dance( uint8_t state[64], uint32_t IV0, uint32_t IV1, 
                               uint32_t IV2, uint32_t IV3 )
```
In the AVR GCC calling convention, the 'state' is passed in r25-r24,
and the 16 bytes of IV are passing in r23-r8. The IV is user
defined. It could be 16 random (key) bytes, a nonce, or counter,
or a combination thereof.

## Operation

The operation of the 'dance' function follows the CFB (Cipher
Feedback) mode of encryption using 16 byte blocks, as follows:
            
```
  [IV]
   |
   v
[ROUND]--> BLOCK0   +--> [ROUND] --> BLOCK1   +--> ...
             |      |                  |      |
             v      ^                  v      ^
    ROW0-->[ADC]-->ROW0       ROW1-->[ADC]-->ROW1 
```

There's a 16 byte BLOCK, initialized once by the IV, and then kept
throughout the entire procedure. The following steps are repeated:

1. mix up the block by applying a round function. 
2. add the block to a row from memory state
3. the output row is fed back and used as next block 

These steps are repeated 4 times, once for each row in the memory. You can
configure total memory size as NR_ROWS. Bigger numbers increase efficiency
at the cost of more memory.

After the entire 64 bytes of state has been updated in a full round, we
start over from the beginnging, but instead of using the IV to initialize
the block, we simply keep the contents from the last row. This ensures that
the bits from each row are getting mixed with bits from every other row. 
The number of times that the entire process is repeated is defined in 
NR_ROUNDS, which is currently defined as 8.

## Performance

For typical case of 4 rows, the code runs at under 8 cycles/byte/round. 
8 rounds on a 16 MHz Arduino can be done in under 4 microseconds/byte.

Total code size is 190 bytes.

## Design of round function

The round function is made from 8 bit operations that run
efficiently on an AVR. The goal was to keep 16 bytes of state in 
registers, and to mix those 16 bytes as well as possible in minimum
number of instruction. The overall design was inspired by ChaCha, but
adapted to exploit the strengths of the AVR architecture, and avoid its
weaknesses.

To test candidate sequences, I used the following method: 

1. generate Gray code sequence of 128 bits wide
2. feed Gray code into round candidate.
3. repeat the same round function for 2nd time
4. run output through PractRand

Step 3 is necessary to get the randomness in a range that's testable
with PractRand. If you only use 1 iteration, it will rapidly fail every
possible candidate. With 2 iterations it's just good enough that most
sequences will fail, but some will run into the terabyte range.

(For comparison, the ChaCha round function must be repeated 3 times 
before satisfying PractRand.)

Test sequence candidates were improved with a simple genetic algorithm. 
The search space was manually limited to a certain set of operations:

- write each register exactly twice
- use mostly ADC, but replace a few with SWAP/EOR to improve results
- chain the operations, so output at step N is input at step N+1

I tried several other combinations, and this approach was most successful,
but it's by no means an exhaustive search. I'm sure there's room for 
improvement, if you have the patience to run the tests. The benefit of
SWAP/EOR is also that it breaks up the fixed ADC pattern with something
completely different, making it less likely someone finds a clever shortcut.


Alternatives
------------
The first version of this code had a 2x bigger round function, 
and fewer rounds. Because of the bigger round function, there's a 
higher percentage of bit manipulation compared to LD/ST overhead, 
likely resulting in better speed for the same security margin. 
However in the face of unknown challenges, it feels better to have 
more rounds, but then the original round function may be a bit of overkill. 
If you do prefer a stronger function, the current round function 
could be repeated twice in a row.

Applications
------------
The applications of this function are very similar to how one would
use the ChaCha/Salsa cipher. You can fill the initial state with a
key, and fill the IV with a nonce/counter to produce 64 bytes of random
data. After a call, the state can be reinitialized, or it can be 
left to be recycled in the next call. Resetting the state means you can
do random access to different offsets in the stream. 

Output data can be used to generate secure random numbers, such as for
passwords/private keys, or it can be used in a stream cipher.



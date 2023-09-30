/*
 * dance.S -- small, fast, cryptographically secure pseudo random generator
 * optimized for Microchip AVR (Arduino)
 *
 * copyright 2023 (C) Arlet Ottens <arlet@c-scape.nl>
 *
 */

#define NR_ROWS     4   // memory rows used, each row is 16 bytes
#define NR_ROUNDS   8   // number of full rounds, more is better/slower

/*
 *
 * The 'dance()' function is called with a pointer to a 64 byte
 * state array, followed by 16 bytes worth of initialization vector
 * (IV). The IV can be as any combination of uint8_t, uint16_t,
 * uint32_t or uint64_t, as long as they add up to exactly 16 bytes.
 *
 * here's a few examples:
 *
 * void dance( uint8_t state[64], uint64_t IV0, uint64_t IV1 )
 *
 * void dance( uint8_t state[64], uint32_t IV0, uint32_t IV1, 
 *                                uint32_t IV2, uint32_t IV3 )
 *
 * void dance( uint8_t state[64], uint64_t IV0, uint32_t IV1,
 *                                uint16_t IV2, uint16_t IV3 )
 *
 * In the AVR GCC calling convention, the 'state' is passed in r25-r24,
 * and the 16 bytes of IV are passing in r23-r8. The IV is user
 * defined. It could be 16 random (key) bytes, a nonce, or counter,
 * or a combination thereof.
 *
 * Operation
 * ---------
 *
 * The operation of the 'dance' function follows the CFB (Cipher
 * Feedback) mode of encryption using 16 byte blocks, as follows:
 *             
 *   [IV]
 *    |
 *    v
 * [ROUND]--> BLOCK0   +--> [ROUND] --> BLOCK1   +--> ...
 *              |      |                  |      |
 *              v      ^                  v      ^
 *     ROW0-->[MIX]-->ROW0       ROW1-->[MIX]-->ROW1 
 *
 * There's a 16 byte BLOCK, initialized once by the IV, and then kept
 * throughout the entire procedure. The following steps are repeated:
 * 
 * 1) mix up the block by applying a round function. 
 * 2) mix the block with 16 byte row from memory state, using ADC/SBC/EOR
 * 3) the output row is fed back and used as next block 
 *
 * These steps are repeated 4 times, once for each row in the memory. You can
 * configure total memory size as NR_ROWS. Bigger numbers increase efficiency
 * at the cost of more memory.
 * 
 * After the entire 64 bytes of state has been updated in a full round, we
 * start over from the beginnging, but instead of using the IV to initialize
 * the block, we simply keep the contents from the last row. This ensures that
 * the bits from each row are getting mixed with bits from every other row. 
 * The number of times that the entire process is repeated is defined in 
 * NR_ROUNDS, which is currently defined as 8.
 *
 * Performance
 * -----------
 * For typical case of 4 rows, the code runs at under 8 cycles/byte/round. 
 * 8 rounds on a 16 MHz Arduino can be done in under 4 microseconds/byte.
 *
 * Total code size is 190 bytes.
 *
 * Design of round function
 * --------------------------------
 * The round function is made from 8 bit operations that run
 * efficiently on an AVR. The goal was to keep 16 bytes of state in 
 * registers, and to mix those 16 bytes as well as possible in minimum
 * number of instruction. The overall design was inspired by ChaCha, but
 * adapted to exploit the strengths of the AVR architecture, and avoid its
 * weaknesses.
 *
 * To test candidate sequences, I used the following method: 
 * 
 * 1) generate Gray code sequence of 128 bits wide
 * 2) feed Gray code into round candidate.
 * 3) repeat the same round function for 2nd time
 * 4) run output through PractRand
 *
 * Step 3 is necessary to get the randomness in a range that's testable
 * with PractRand. If you only use 1 iteration, it will rapidly fail every
 * possible candidate. With 2 iterations it's just good enough that most
 * sequences will fail, but some will run into the terabyte range.
 *
 * (For comparison, the ChaCha round function must be repeated 3 times 
 * before satisfying PractRand.)
 * 
 * Test sequence candidates were improved with a simple genetic algorithm. 
 * The search space was manually limited to a certain set of operations:
 *
 * - write each register exactly twice
 * - use mostly ADC, but replace a few with SWAP/EOR to improve results
 * - chain the operations, so output at step N is input at step N+1
 * 
 * I tried several other combinations, and this approach was most successful,
 * but it's by no means an exhaustive search. I'm sure there's room for 
 * improvement, if you have the patience to run the tests. The benefit of
 * SWAP/EOR is also that it breaks up the fixed ADC pattern with something
 * completely different, making it less likely someone finds a clever shortcut.
 *
 * Alternatives
 * ------------
 * The first version of this code had a 2x bigger round function, 
 * and fewer rounds. Because of the bigger round function, there's a 
 * higher percentage of bit manipulation compared to LD/ST overhead, 
 * likely resulting in better speed for the same security margin. 
 * However in the face of unknown challenges, it feels better to have 
 * more rounds, but then the original round function may be a bit of overkill. 
 * If you do prefer a stronger function, the current round function 
 * could be repeated twice in a row.
 *
 * Applications
 * ------------
 * The applications of this function are very similar to how one would
 * use the ChaCha/Salsa cipher. You can fill the initial state with a
 * key, and fill the IV with a nonce/counter to produce 64 bytes of random
 * data. After a call, the state can be reinitialized, or it can be 
 * left to be recycled in the next call. Resetting the state means you can
 * do random access to different offsets in the stream. 
 *
 * Output data can be used to generate secure random numbers, such as for
 * passwords/private keys, or it can be used in a stream cipher.
 * 
 */

; helper macros for mixing the current row state with memory array
; The Z pointer is used to read/write a row byte, and it is auto 
; incremented in this macro

.macro  adcz reg
        ld      r0, Z           ; load memory byte
        adc     \reg, r0        ; mix with byte from state
        st      Z+, \reg        ; write back to memory
.endm

.macro  sbcz reg
        ld      r0, Z           ; load memory byte
        sbc     \reg, r0        ; mix with byte from state
        st      Z+, \reg        ; write back to memory
.endm

.macro  eorz reg
        ld      r0, Z           ; load memory byte
        eor     \reg, r0        ; mix with byte from state
        st      Z+, \reg        ; write back to memory
.endm

; the actual function. 
; 
; we use registers r8-r23 for the block data. Since the function definition
; puts the IV argument in these registers, we don't have to initialize them.
;
; register pair r25-r24 contains address of state. These registers are not
; modified so that they can be copied into Z when we reset for the next 
; round. Registers r26 and r27 are used for round & row counters. 

        .text
        .global dance
        .type   dance, @function

dance:
        sec                     ; set carry once 
        ldi     r26, NR_ROUNDS  ; load number of rounds
.first_row: 
        ldi     r27, NR_ROWS    ; load number of rows per round
        movw    Z, r24          ; load start of state in Z pointer
.next_row:

    ; perform round function on block data

        adc     r9, r8
        adc     r10, r9
        adc     r11, r10
        adc     r12, r11
        swap    r12
        eor     r13, r12
        adc     r14, r13
        adc     r15, r14
        adc     r16, r15
        adc     r17, r16
        adc     r18, r17
        adc     r14, r18
        adc     r19, r14
        adc     r11, r19
        adc     r20, r11
        adc     r21, r20
        adc     r19, r21
        adc     r22, r19
        adc     r12, r22
        swap    r12
        eor     r15, r12
        adc     r18, r15
        adc     r22, r18
        adc     r23, r22
        swap    r23
        eor     r10, r23
        adc     r17, r10
        adc     r20, r17
        swap    r20
        eor     r8, r20
        adc     r23, r8
        adc     r21, r23
        adc     r9, r21
        adc     r13, r9
        adc     r8, r13
        adc     r16, r8

    ; now read 16 bytes from memory area pointed by 'Z',
    ; mix it with the state, and write it back.
    ; The 'Z' register is incremented along.

    ; randomly alternate between ADC/SBC/EOR to reduce 
    ; the chance of accidental exploitable patterns

        adcz    r8
        sbcz    r9
        eorz    r10
        adcz    r11
        adcz    r12
        sbcz    r13
        adcz    r14
        adcz    r15
        sbcz    r16
        eorz    r17
        sbcz    r18
        eorz    r19
        adcz    r20
        sbcz    r21
        adcz    r22
        sbcz    r23

    ; now repeat next row. Be careful to only use
    ; instructions that preserve the carry flag.

        dec     r27 
        breq    .done_block
        rjmp    .next_row
.done_block:
        dec     r26
        breq    .done_all
        rjmp    .first_row

.done_all:
        ret

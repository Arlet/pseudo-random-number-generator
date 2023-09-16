;
; dance.S -- cryptographically secure pseudo random generator
;
; copyright 2023 (C) Arlet Ottens <arlet@c-scape.nl>
;
;
; R2-R17, R28-R29 (Y) are callee saved
; R1 must be 0
; X = R26:R27
; Y = R28:R29
; Z = R30:R31

#define NR_ROWS     4
#define NR_ROUNDS   4

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
 * In the AVR GCC calling convention, the 'state' is passed in r25-r24,
 * and the 16 bytes of IV are passing in r23-r8. The "IV" is user
 * defined. It could be 16 random (key) bytes, a nonce, or counter,
 * or a combination thereof.
 *
 *
 * OPERATION
 * =========
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
 *     ROW0-->[ADC]-->ROW0       ROW1-->[ADC]-->ROW1 
 *
 * There's a 16 byte BLOCK, initialized once by the IV, and then kept
 * throughout the entire procedure. The following steps are repeated:
 * 
 * 1) mix up the block by applying a round function. 
 * 2) add the block to a row from memory state
 * 3) the output row is fed back and used as next block 
 *
 * These steps are repeated 4 times, once for each row in the memory. You can
 * configure total memory size as NR_ROWS. Bigger numbers increase effficiency
 * at the cost of more memory.
 * 
 * If we stop here, it would be a decent random generator, but it wouldn't
 * be secure. To improve security, we start the process over from the beginning
 * but instead of using the IV to initialize the block, we simply keep the
 * block contents from the last row. This ensures that the bits from each
 * row are getting mixed with bits from every other row. The number of times
 * that the entire process is repeated is defined in NR_ROUNDS. 
 *
 * Performance
 * -----------
 * For typical case of 4 rows, the code runs at 10 cycles/byte/round. 
 * So for 4 rounds on a 16 MHz Arduino, that's 2.5 microseconds/byte.
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
 * private keys, or it can be used in a stream cipher.
 * 
 */

; helper macro for mixing the current row state with memory array
; traditionally this is done with XOR instruction, but we'll use
; ADC to help mix up the carry flag as well. The Z pointer is used
; to read/write a row byte, and it is auto incremented in this macro

.macro  adcz reg
        ld      r0, Z           ; load memory byte
        adc     \reg, r0        ; mix with byte from state
        st      Z+, \reg        ; write back to memory
.endm

;
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

        adc     r20, r8
        adc     r21, r20
        adc     r22, r21
        adc     r9, r22
        adc     r8, r9
        adc     r19, r8
        adc     r14, r19
        swap    r14
        eor     r13, r14
        adc     r13, r13
        adc     r10, r13
        adc     r17, r10
        adc     r11, r17
        adc     r8, r11
        adc     r12, r8
        adc     r14, r12
        adc     r15, r14
        adc     r12, r15
        adc     r18, r12
        adc     r9, r18
        swap    r9
        eor     r11, r9
        adc     r23, r11
        swap    r23
        eor     r19, r23
        adc     r22, r19
        adc     r15, r22
        adc     r22, r15
        adc     r18, r22
        adc     r16, r18
        adc     r11, r16
        adc     r23, r11
        adc     r18, r23
        adc     r12, r18
        adc     r20, r12
        adc     r17, r20
        adc     r15, r17
        swap    r15
        eor     r9, r15
        adc     r10, r9
        adc     r13, r10
        adc     r19, r13
        swap    r19
        eor     r17, r19
        adc     r16, r17
        swap    r16
        eor     r23, r16
        swap    r23
        eor     r21, r23
        adc     r9, r21
        adc     r14, r9
        adc     r12, r14
        adc     r20, r12
        swap    r20
        eor     r15, r20
        adc     r23, r15
        adc     r11, r23
        adc     r10, r11
        adc     r22, r10
        adc     r19, r22
        adc     r20, r19
        adc     r17, r20
        adc     r8, r17
        adc     r21, r8
        adc     r16, r21
        adc     r8, r16
        adc     r13, r8
        adc     r21, r13
        adc     r10, r21
        adc     r14, r10
        adc     r16, r14
        adc     r18, r16

    ; now read 16 bytes from memory area pointed by 'Z',
    ; mix it with the state, and write it back.
    ; The 'Z' register is incremented along.

        adcz    r8
        adcz    r9
        adcz    r10
        adcz    r11
        adcz    r12
        adcz    r13
        adcz    r14
        adcz    r15
        adcz    r16
        adcz    r17
        adcz    r18
        adcz    r19
        adcz    r20
        adcz    r21
        adcz    r22
        adcz    r23

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

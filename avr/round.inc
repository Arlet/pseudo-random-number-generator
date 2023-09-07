/*
 * round.inc -- randomizing round function for AVR
 * 
 * Copyright 2023 Arlet Ottens <arlet@c-scape.nl>
 *
 * this function takes 16 byte state in registers r8-r23,
 * and attempts to create maximum amount of diffusion in 
 * limited number of cycles (I chose a limit of 72 cycles)
 *
 * Code has been optimized using PractRand, using testbench
 * where r8-r12 are incremented as a 40 bit counter, and 
 * r13-r23 are initialized at zero. For each iteration, a single
 * round function is applied, and the output is sent to 
 * PractRand for testing. The code below passes 1TB of 
 * data, and is the best I have found so far (given more time and 
 * effort, I'm sure it can be improved)
 *
 * The idea is to use this round function as part of a bigger
 * project for pseudo random number generation, possibly 
 * cryptographically secure.
 */

        adc     r14, r8
        adc     r13, r14
        adc     r10, r13
        adc     r22, r10
        adc     r19, r22
        adc     r20, r19
        adc     r16, r20
        adc     r22, r16
        swap    r22
        eor     r9, r22
        adc     r21, r9
        adc     r18, r21
        adc     r19, r18
        adc     r12, r19
        adc     r9, r12
        adc     r13, r9
        adc     r22, r13
        adc     r10, r22
        adc     r15, r10
        adc     r18, r15
        swap    r18
        eor     r11, r18
        adc     r15, r11
        adc     r10, r15
        adc     r23, r10
        adc     r17, r23
        adc     r9, r17
        adc     r20, r9
        adc     r17, r20
        swap    r17
        eor     r15, r17
        adc     r8, r15
        adc     r18, r8
        swap    r18
        eor     r21, r18
        adc     r14, r21
        adc     r19, r14
        adc     r21, r19
        adc     r11, r21
        swap    r11
        eor     r23, r11
        adc     r14, r23
        adc     r18, r14
        adc     r15, r18
        swap    r15
        eor     r13, r15
        adc     r20, r13
        adc     r16, r20
        adc     r21, r16
        adc     r23, r21
        adc     r17, r23
        adc     r8, r17
        adc     r11, r8
        swap    r11
        eor     r19, r11
        adc     r13, r19
        adc     r9, r13
        adc     r23, r9
        adc     r12, r23
        adc     r11, r12
        swap    r11
        eor     r17, r11
        adc     r16, r17
        adc     r22, r16
        adc     r20, r22
        adc     r12, r20
        adc     r10, r12
        adc     r8, r10
        adc     r16, r8
        adc     r12, r16
        adc     r14, r12
        adc     r8, r14

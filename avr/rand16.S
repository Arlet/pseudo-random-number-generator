;
; rand16.S -- 16 byte random generator 
;
; copyright 2023 (C) Arlet Ottens <arlet@c-scape.nl>
;

; R2-R17, R28-R29 (Y) are callee saved
; R1 must be 0
; X = R26:R27
; Y = R28:R29
; Z = R30:R31

; function prototype:
;
; uint32_t rand16( uint8_t state[16] )
;
; state refers to a 16 byte array. If you prefer you can redefine
; the state as 4x32 bit, or 8x16 bit.
;
; after calling the function, you can either use the 32 bit return
; value as a random number, or you can copy values from the state[]
; array

        .global rand16
        .type   rand16, @function
rand16:
        push    r14             ; free up some more registers
        push    r15
        push    r16
        push    r17
        movw    Z, r24          ; get pointer to state in Z

    ; load state in 16 registers

        ld      r0, Z+   
        ld      r1, Z+
        ld      r14, Z+
        ld      r15, Z+
        ld      r16, Z+
        ld      r17, Z+
        ld      r18, Z+
        ld      r19, Z+
        ld      r20, Z+
        ld      r21, Z+
        ld      r22, Z+
        ld      r23, Z+
        ld      r24, Z+
        ld      r25, Z+
        ld      r26, Z+
        ld      r27, Z+

        sec                     ; init carry = 1 

    ; randomize state

        adc     r24, r18
        adc     r23, r24
        adc     r20, r23
        adc     r16, r20
        adc     r1, r16
        adc     r14, r1
        adc     r26, r14
        adc     r16, r26
        swap    r16
        eor     r19, r16
        adc     r15, r19
        adc     r0, r15
        adc     r1, r0
        adc     r22, r1
        adc     r19, r22
        adc     r23, r19
        adc     r16, r23
        adc     r20, r16
        adc     r25, r20
        adc     r0, r25
        swap    r0
        eor     r21, r0
        adc     r25, r21
        adc     r20, r25
        adc     r17, r20
        adc     r27, r17
        adc     r19, r27
        adc     r14, r19
        adc     r27, r14
        swap    r27
        eor     r25, r27
        adc     r18, r25
        adc     r0, r18
        swap    r0
        eor     r15, r0
        adc     r24, r15
        adc     r1, r24
        adc     r15, r1
        adc     r21, r15
        swap    r21
        eor     r17, r21
        adc     r24, r17
        adc     r0, r24
        adc     r25, r0
        swap    r25
        eor     r23, r25
        adc     r14, r23
        adc     r26, r14
        adc     r15, r26
        adc     r17, r15
        adc     r27, r17
        adc     r18, r27
        adc     r21, r18
        swap    r21
        eor     r1, r21
        adc     r23, r1
        adc     r19, r23
        adc     r17, r19
        adc     r22, r17
        adc     r21, r22
        swap    r21
        eor     r27, r21
        adc     r26, r27
        adc     r16, r26
        adc     r14, r16
        adc     r22, r14
        adc     r20, r22
        adc     r18, r20
        adc     r26, r18
        adc     r22, r26
        adc     r24, r22
        adc     r18, r24

    ; now write back state

        st      -Z, r27         
        st      -Z, r26
        st      -Z, r25         ; these 4 registers are 
        st      -Z, r24         ; returned as result
        st      -Z, r23         ;
        st      -Z, r22         ;
        st      -Z, r21
        st      -Z, r20
        st      -Z, r19
        st      -Z, r18
        st      -Z, r17
        st      -Z, r16
        st      -Z, r15
        st      -Z, r14
        st      -Z, r1
        st      -Z, r0
        pop     r17
        pop     r16
        pop     r15
        pop     r14
        clr     r1
        ret

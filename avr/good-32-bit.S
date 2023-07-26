;
; fast and high quality PRNG. Takes 51 cycles on Arduino Uno, not
; including call/ret overhead.
;
;
; minimum period is 2^48 states (no bad seed values). Output passes PractRand <= 16TB, and BigCrush.
;
; Copyright (C) Arlet Ottens 2023, <arlet@c-scape.nl>
;
;
        .global rand32

    ; uint32_t rand32( uint8_t *state );

rand32:
        movw    Z, r24      ; get pointer to state

    ; load state in set of 7 working registers

        ld      r19, Z+     ; 
        ld      r20, Z+     ;
        ld      r21, Z+     ;
        ld      r22, Z+     ;
        ld      r23, Z+     ;
        ld      r24, Z+     ;
        ld      r25, Z+     ;

    ; 6 byte iterator using add & subtract with
    ; carry/borrow, guaranteeing a minimum period of 
    ; 2^48 states

        subi    r20, 0x45   ;
        adc     r21, r20    ;
        sbc     r22, r21    ;
        sbc     r23, r22    ;
        adc     r24, r23    ;
        adc     r25, r24    ;
 
    ; write the 6 byte iterator state back to 
    ; memory so that we can use the registers
    ; as temporaries / return value
    
        st      -Z, r25     ; 
        st      -Z, r24     ;
        st      -Z, r23     ;
        st      -Z, r22     ;
        st      -Z, r21     ;
        st      -Z, r20     ;

    ; now perform output hash function, using r19
    ; as additional state byte

        eor     r23, r21    ;
        swap    r23         ;
        adc     r22, r23    ;
        adc     r24, r22    ;
        swap    r24         ;
        eor     r25, r24    ;
        adc     r19, r25    ;
        eor     r24, r19    ;
        adc     r22, r24    ;
        swap    r22         ;
        eor     r19, r22    ;
        adc     r23, r19    ;
        adc     r25, r23    ;
        adc     r22, r25    ;
        adc     r19, r22    ;
        adc     r24, r19    ;

    ; write updated value of r19 back to memory

        st      -Z, r19     ; 

    ; return with 32 bit random value in r25-r22

        ret


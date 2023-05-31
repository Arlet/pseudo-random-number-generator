;
; fast PRNG (pseudo random number generator)
; written in 6502 assembly language
;
; (C) Arlet Ottens 2023 <arlet@c-scape.nl> 
;

; the label 's' refers to a 5 byte RAM area that must be initialized
; with a random seed value. Any seed value will do, and will result in 
; a guaranteed minimum period of 4G byte.
; 
; the subroutine returns two random bytes in 'o' area. 
;
; the out of this random number generator passes PractRand up to 4GB output
; using all zero seed
;
prng:
    CLC
    LDA #$45
    ADC s+0
    STA s+0
    ADC s+1
    STA s+1
    ADC s+2
    STA s+2
    ADC s+3
    STA s+3
    LDA s+4
    ROL A
    STA s+4
    ADC s+2
    STA o+0
    ADC s+3
    STA o+1
    ADC s+1
    ROL A
    ADC o+0
    STA o+0
    ADC s+4
    STA s+4
    ADC o+1
    STA o+1
    RTS

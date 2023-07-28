;
; fast PRNG (pseudo random number generator)
; written in 6502 assembly language
;
; (C) Arlet Ottens 2023 <arlet@c-scape.nl> 
;

; the label 'state' refers to a 8 byte RAM area that must be initialized
; with a random seed value. Any seed value will do, and will result in 
; a guaranteed minimum period of 1T byte.
; 
; the subroutine returns a random byte in the accumulator
;
; the output of this random number generator passes PractRand up to 4TB output
; using all zero seed
;
prng:
    CLC
    LDA #&45
    ADC state+0
    STA state+0
    ADC state+1
    STA state+1
    ADC state+2
    STA state+2
    ADC state+3
    STA state+3
    ADC state+4
    STA state+4
    LDA state+5
    EOR state+7
    ADC state+4
    STA state+5
    ADC state+6
    STA state+6
    LDA state+7
    ASL
    ADC state+6
    STA state+7
    EOR state+2
    RTS

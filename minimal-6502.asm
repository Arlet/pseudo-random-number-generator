;
; fast PRNG (pseudo random number generator)
; written in 6502 assembly language
;
; (C) Arlet Ottens 2023 <arlet@c-scape.nl> 
;

; the label 'state' refers to a 6 byte RAM area that must be initialized
; with a random seed value. Any seed value will do, and will result in 
; a minimum period of 4G byte.
; 
; the subroutine returns a random byte in the accumulator
;
; the code takes 46 cycles for the actual update, plus 12 cycles for the 
; JSR/RTS overhead if used as a subroutine.
;
; the output of this random number generator passes Dieharder as well as
; PractRand up to 4GB output.
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
    EOR state+4
    ADC state+5
    STA state+4
    ADC state+5
    EOR state+2
    STA state+5
    RTS

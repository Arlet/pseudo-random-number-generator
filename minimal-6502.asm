;
; fast PRNG (pseudo random number generator) written in 6502 assembly
; language. Code is optimized for speed and memory footprint, while 
; still producing good quality random numbers for 6502-based platforms. 
;
; (C) Arlet Ottens 2023 <arlet@c-scape.nl> 
;
; the label 'state' refers to a 5 byte RAM area that must be initialized
; with a random seed value. Any seed value will do, and will result in 
; a minimum period of 4G byte.
; 
; the subroutine returns a random byte in the accumulator
;
; the code takes 42 cycles for the actual update, plus 12 cycles for the 
; JSR/RTS overhead if used as a subroutine. The 'state' is assumed to be 
; in zero page. You can move the state to other memory at the cost of 
; 12 additional cycles for absolute accesses.
;
; the output of this random number generator passes Dieharder as well as
; PractRand up to 2GB output.
;
prng:
    CLC
    LDA #$41
    ADC state+0
    STA state+0
    ADC state+1
    STA state+1
    ADC state+2
    STA state+2
    ADC state+3
    STA state+3
    ADC state+4
    ASL
    ADC state+3
    STA state+4
    EOR state+2
    RTS

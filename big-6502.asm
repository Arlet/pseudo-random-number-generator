;
; fast PRNG (pseudo random number generator)
; written in 6502 assembly language
;
; (C) Arlet Ottens 2023 <arlet@c-scape.nl> 
;

; the label 's' refers to a 6 byte RAM area that must be initialized
; with a random seed value. Any seed value will do, and will result in 
; an exact period of 256T (2^48). 
; 
; the label 'o' refers to a 4 byte output area where the 32 bit random 
; number will be stored
;
; The random generator has good quality for its size (passes 256GB in PractRand).
;
prng:
    CLC
    LDA #&45
    ADC s+0
    STA s+0
    ADC s+1
    STA s+1
    ADC s+2
    STA s+2
    ADC s+3
    STA s+3
    ADC s+4
    STA s+4
    ADC s+5
    STA s+5
    LDA s+2
    ASL
    ADC s+5
    STA o+0
    ADC s+3
    STA o+1
    ADC s+4
    STA o+3
    LDA o+2
    ASL
    ADC o+3
    STA o+2
    ADC o+0
    STA o+0
    ADC o+1
    ASL
    ADC o+0
    STA o+1
    ADC o+3
    STA o+3
    ADC o+2
    ASL
    ADC o+3
    STA o+2
    ADC o+1
    STA o+1
    ADC o+0
    STA o+0
    RTS

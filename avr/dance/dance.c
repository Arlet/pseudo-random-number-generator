/*
 * dance.c -- C version of 'dance' secure random generator for AVR
 * 
 * Copyright 2023 Arlet Ottens <arlet@c-scape.nl>
 */

#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define SWAP( a )                   \
    do {                            \
        a = ((a) << 4) | ((a) >> 4);\
    } while (0)

#define EOR( a, b )                 \
    do {                            \
        a ^= (b);                   \
    } while (0)

#define ADC( a, b )                 \
    do {                            \
        x = a + (b) + ((x >> 8)&1); \
        a = x;                      \
    } while (0)

#define SBC( a, b )                 \
    do {                            \
        x = a - (b) - ((x >> 8)&1); \
        a = x;                      \
    } while (0)

#define SEC( )                      \
    do {                            \
        x = 0x100;                  \
    } while (0)

#define SBCZ( a )                   \
    do {                            \
        SBC( a, *Z );               \
        *Z++ = a;                   \
    } while (0)

#define EORZ( a )                   \
    do {                            \
        EOR( a, *Z );               \
        *Z++ = a;                   \
    } while (0)

#define ADCZ( a )                   \
    do {                            \
        ADC( a, *Z );               \
        *Z++ = a;                   \
    } while (0)

void dance( uint8_t mem[64], uint32_t iv0, uint32_t iv1, uint32_t iv2, uint32_t iv3 )
{
    uint16_t x; // x is used in ADC/SBC macros for holding carry
    int row, round;

    // split arguments in registers according to AVR calling convention
    uint8_t r8  = iv3;
    uint8_t r9  = iv3 >> 8;
    uint8_t r10 = iv3 >> 16;
    uint8_t r11 = iv3 >> 24;
    uint8_t r12 = iv2;
    uint8_t r13 = iv2 >> 8;
    uint8_t r14 = iv2 >> 16;
    uint8_t r15 = iv2 >> 24;
    uint8_t r16 = iv1;
    uint8_t r17 = iv1 >> 8;
    uint8_t r18 = iv1 >> 16;
    uint8_t r19 = iv1 >> 24;
    uint8_t r20 = iv0;
    uint8_t r21 = iv0 >> 8;
    uint8_t r22 = iv0 >> 16;
    uint8_t r23 = iv0 >> 24;

    SEC( );
    for( round = 0; round < 8; round++ )
    {
        uint8_t *Z = mem;

        for( row = 0; row < 4; row++ )
        {
            // round function
            ADC( r9, r8 );
            ADC( r10, r9 );
            ADC( r11, r10 );
            ADC( r12, r11 );
            SWAP( r12 );
            EOR( r13, r12 );
            ADC( r14, r13 );
            ADC( r15, r14 );
            ADC( r16, r15 );
            ADC( r17, r16 );
            ADC( r18, r17 );
            ADC( r14, r18 );
            ADC( r19, r14 );
            ADC( r11, r19 );
            ADC( r20, r11 );
            ADC( r21, r20 );
            ADC( r19, r21 );
            ADC( r22, r19 );
            ADC( r12, r22 );
            SWAP( r12 );
            EOR( r15, r12 );
            ADC( r18, r15 );
            ADC( r22, r18 );
            ADC( r23, r22 );
            SWAP( r23 );
            EOR( r10, r23 );
            ADC( r17, r10 );
            ADC( r20, r17 );
            SWAP( r20 );
            EOR( r8, r20 );
            ADC( r23, r8 );
            ADC( r21, r23 );
            ADC( r9, r21 );
            ADC( r13, r9 );
            ADC( r8, r13 );
            ADC( r16, r8 );

            // state mix 
            ADCZ( r8 );
            SBCZ( r9 );
            EORZ( r10 );
            ADCZ( r11 );
            ADCZ( r12 );
            SBCZ( r13 );
            ADCZ( r14 );
            ADCZ( r15 );
            SBCZ( r16 );
            EORZ( r17 );
            SBCZ( r18 );
            EORZ( r19 );
            ADCZ( r20 );
            SBCZ( r21 );
            ADCZ( r22 );
            SBCZ( r23 );
        }
    }
}

void test( uint8_t state[64], uint32_t iv0, uint32_t iv1, uint32_t iv2, uint32_t iv3 )
{
    int i, j;

    for( j = 0; j < 2; j++ )
    {
        dance( state, iv0, iv1, iv2, iv3 );
        for( i = 0; i < 64; i++ )
            printf( "%02x%c", state[i], i % 16 == 15 ? '\n' : ' ' );
        printf( "\n" );
    }
}

int main( int argc, char **argv )
{
    uint8_t state[64];
    uint8_t check[64] = 
    {
        0xdc, 0xd0, 0x65, 0xe4, 0x78, 0xcd, 0xd3, 0xe6,
        0x11, 0xe1, 0x09, 0xe8, 0xa2, 0x6a, 0x94, 0x63,
        0xce, 0x41, 0x1d, 0xd0, 0x26, 0x7c, 0x78, 0xa5,
        0x4a, 0xb3, 0x1f, 0xed, 0xff, 0xc4, 0xf1, 0x28,
        0x4b, 0x19, 0xee, 0x0b, 0x4a, 0xb9, 0x5b, 0x34,
        0x4d, 0xca, 0x1a, 0x2a, 0x1a, 0x1f, 0x9f, 0x8d,
        0xdc, 0xd9, 0xb5, 0xb2, 0x7c, 0x4a, 0xd4, 0x53,
        0xc1, 0x2f, 0x33, 0x23, 0x6e, 0x93, 0xba, 0x35,
    };

    memset( state, 0, 64 );
    test( state, 0, 0, 0, 0  );
    test( state, 0x01234567, 0x89abcdef, 0x08192a3b, 0x4c5d6e7f  );
    if( memcmp(state, check, 64) )
        printf( "bad result\n" );
    else
        printf( "good result\n" );
}

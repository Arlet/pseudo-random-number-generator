/*
 * medium-6502.c
 *
 * C version of the medium-6502.asm code for testing
 *
 * (C) Arlet Ottens 2023 <arlet@c-scape.nl>
 */

#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#endif

#define EOR( a, b )                 \
    do {                            \
        a ^= (b);                   \
    } while (0)

#define ADD( a, b )                 \
    do {                            \
        x = a + (b);                \
        a = x;                      \
    } while (0)

#define ADC( a, b )                 \
    do {                            \
        x = a + (b) + (x >> 8) % 2; \
        a = x;                      \
    } while (0)

int main( void )
{
    static char buf[65536];
    uint8_t s0 = 0, s1 = 0, s2 = 0, s3 = 0, s4 = 0, s5 = 0, s6 = 0, s7 = 0;
    uint8_t o0;
    uint32_t x;

    setvbuf( stdout, buf, _IOFBF, sizeof(buf) ); 
#ifdef _WIN32
    _setmode(_fileno(stdout), _O_BINARY);
#endif
    while( 1 )
    {
        ADD( s0, 0x45 );
        ADC( s1, s0 ); 
        ADC( s2, s1 );
        ADC( s3, s2 );
        ADC( s4, s3 );
        EOR( s5, s7 );
        ADC( s5, s4 );
        ADC( s6, s5 );
        ADD( s7, s7 );
        ADC( s7, s6 );
        o0 = s7;
        EOR( o0, s2 );

        putchar( o0 );
    }
}

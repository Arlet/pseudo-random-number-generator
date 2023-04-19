/*
 * minimal-6502.c
 *
 * C version of the minimal-6502.asm code for testing
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
    uint8_t s0 = 0, s1 = 0, s2 = 0, s3 = 0, s4 = 0;
    unsigned int x;

    setvbuf( stdout, buf, _IOFBF, sizeof(buf) ); 
#ifdef _WIN32
    _setmode(_fileno(stdout), _O_BINARY);
#endif
    while( 1 )
    {
        ADD( s0, 0x41 );
        ADC( s1, s0 ); 
        ADC( s2, s1 );
        ADC( s3, s2 );
        ADC( s4, s3 );
        ADD( s4, s4 );
        ADC( s4, s3 );
        putchar( s4 ^ s2 );
    }
}

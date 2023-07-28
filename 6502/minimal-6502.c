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

/*
 * ADD without carry. This instruction is not
 * available on the 6502, but can be implemented
 * by CLC followed by ADC.  When ADD(p, p) is used
 * the 6502 can implement that as a 1-bit shift left
 * (ASL) instruction.
 * 
 * The 'x' variable must be declared in the scope
 * of the caller and will store the carry output
 * in bit 8.
 */
#define ADD( a, b )                 \
    do {                            \
        x = a + (b);                \
        a = x;                      \
    } while (0)

/*
 * ADD with carry. The expression 'b' is added to
 * variable 'a' using the carry flag stored in bit 8
 * of variable x.
 */
#define ADC( a, b )                 \
    do {                            \
        x = a + (b) + (x >> 8) % 2; \
        a = x;                      \
    } while (0)

/*
 * main loop, produce random output and send it to stdout
 */
int main( void )
{
    // 5 bytes of state
    uint8_t s0 = 0, s1 = 0, s2 = 0, s3 = 0, s4 = 0;

    // x stores the current carry flag in bit 8
    unsigned int x;

    // use a big output buffer to increase putchar() speed 
    static char buf[65536];
    setvbuf( stdout, buf, _IOFBF, sizeof(buf) ); 
#ifdef _WIN32
    _setmode(_fileno(stdout), _O_BINARY);
#endif

    // random generator loop
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

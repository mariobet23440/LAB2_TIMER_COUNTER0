;
; Lab2_Timer_Counter0.asm
;
; Created: 14/02/2025 00:07:08
; Author : mario
;

.include "M328PDEF.inc"
.cseg
.org    0x0000

// Lookup Table para Display de 7 Segmentos
.equ SEVENSD1 =	0b0010_0001
.equ SEVENSD2 =	0b0011_1011
.equ SEVENSD3 =	0b0110_1011
.equ SEVENSD4 =	0b0010_0001
.equ SEVENSD5 =	0b0110_1110
.equ SEVENSD6 =	0b0111_1110
.equ SEVENSD7 =	0b0001_0110
.equ SEVENSD8 =	0b0111_1111
.equ SEVENSD9 =	0b0100_1111
.equ SEVENSDA =	0b0101_1111
.equ SEVENSDB =	0b0111_1100
.equ SEVENSDC =	0b0010_0001
.equ SEVENSDD =	0b0111_0111
.equ SEVENSDE =	0b0011_1110
.equ SEVENSDF =	0b0001_1110

// Configurar la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16

SETUP:
    // Activación de pines de entrada y salida en el puerto C
    LDI     R16, 0x0F	// Primeros cuatro bits como salidas y los primeros dos bits como entradas
    OUT     DDRB, R16
    LDI     R16, 0xF0	// Activar Pull-ups en entradas y desactivar salidas inicialmente
    OUT     PORTB, R16

    // Activación de pines de salida en el puerto D
    LDI     R16, 0xFF
    OUT     DDRD, R16
    LDI     R16, 0x00
    OUT     PORTD, R16

    // Registros de contadores
	LDI     R16, 0x00


MAINLOOP:


SEVEN_SEGMENT_DISPLAY:
	
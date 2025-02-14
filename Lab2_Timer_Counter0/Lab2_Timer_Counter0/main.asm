;
; Lab2_Timer_Counter0.asm
;
; Created: 14/02/2025 00:07:08
; Author : mario
;

/*
CONFIGUACIÓN DE TIMER0
Estamos usando TIMER0 como un temporizador en modo NORMAL. 
t_delay = 100 ms
f_clk = 1 MHz
n = 8 (Recordemos que es el número de bits del registro del *contador*)

Prescaler >= (t_delay * f_clk) / 2**n = (0.1*10E6)(2POW(8)) = 390
Prescaler >= 390
Escogemos un prescaler de 1024

Calculamos el tiempo máximo que puede contar TIMER0
Tmax = (2**n * Prescaler) / f_clk = (2**8 * 1024) / 10E6 = 0.262s = 262 ms 

Determinamos el valor inicial de TIMER0
TCNT0 = 256 - (f_clk * t_deseado) / Prescaler = 256 - (10E6 * 0.100) / 1024 = 158

Con este cálculo el contador alcanza 100 ms directamente por cada conteo realizado.
*/


// Encabezado
.include "M328PDEF.inc"
.cseg
.org    0x0000

// Definiciones
.equ PRESCALER = (1<<CS01) | (1<<CS00)
.equ TIMER_START = 158                   ; Valor inicial del Timer0
.equ OVERFLOWS = 10                      ; Cantidad de desbordamientos para 100 ms
.def COUNTER = R20						 ; REGISTRO A MOSTRAR EN PUERTOS

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
    OUT     DDRC, R16
    LDI     R16, 0xF0	// Activar Pull-ups en entradas y desactivar salidas inicialmente
    OUT     PORTC, R16

	// Configurar Prescaler Principal
	LDI		R16, (1 << CLKPCE)
	STS     CLKPR, R16          // Habilitar cambio de PRESCALER
    LDI     R16, 0x04
    STS     CLKPR, R16          // Configurar Prescaler a 1 Mhz

	// Inicializar timer0
    CALL    INIT_TMR0


MAIN_LOOP:
    // Revisión de la bandera de Overflow en TIMER0
	IN      R16, TIFR0          // Leer registro de interrupción de TIMER0
    SBRS    R16, TOV0           // Salta si el bit 0 está "set" (TOV0 bit, Bandera de Overflow)
    RJMP    MAIN_LOOP           // Reiniciar loop
	
	// Si el reloj alcanza un desborde, se ejecuta el siguiente fragmento de código
	SBI     TIFR0, TOV0         // Limpiar bandera de "overflow" (No se limpia automáticamente)
	LDI     R16, TIMER_START    // Establecer el valor inicial del contador TCNT0
    OUT     TCNT0, R16          // Volver a cargar valor inicial en TCNT0 
    RJMP    MAIN_LOOP			// Regresar a Mainloop


// Inicializar Timer0
INIT_TMR0:
    LDI     R16, PRESCALER				// Configurar un registro para setear las posiciones de CS01 y CS00
    OUT     TCCR0B, R16					// Setear prescaler del TIMER0 a 64 (CS01 = 1 y CS00 = 0)
    LDI     R16, TIMER_START			// Empezar el conteo con un valor de 100
    OUT     TCNT0, R16					// Cargar valor inicial en TCNT0
    RET

		
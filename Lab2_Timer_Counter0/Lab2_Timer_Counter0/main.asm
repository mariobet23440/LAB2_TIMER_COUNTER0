;
; Lab2_Timer_Counter0.asm
;
; Created: 14/02/2025 00:07:08
; Author : mario
; Link a Github: https://github.com/mariobet23440/LAB2_TIMER_COUNTER0

/*
- HISTORIAL DE VERSIONES -

ENTREGA DE PRELAB: 14/02/2025 - 14:01
- Implementación del contador con TIMER0.
- Muestra el resultado del contador en los cuatro LEDs y en el display de 7 segmentos.

ENTREGA DE LAB: 14/02/2024 - 18:55
- Implementación de contador con entradas
*/


/*
CONFIGUACIÓN DE TIMER0
Estamos usando TIMER0 como un temporizador en modo NORMAL. 
t_delay = 20 ms
f_clk = 4 MHz
n = 8 (Recordemos que es el número de bits del registro del *contador*)


Prescaler >= (t_delay * f_clk) / 2**n = (0.02)*(4*10E6)/(2POW(8)) = 312.5
Prescaler >= 313
Escogemos un prescaler de 1024

Calculamos el tiempo máximo que puede contar TIMER0
Tmax = (2**n * Prescaler) / f_clk = (2**8 * 1024) / 4 * 10E6 = 0.655s = 65.5 ms 

Determinamos el valor inicial de TIMER0

Si deseamos un delay de 20 ms
TCNT0 = 256 - (f_clk * t_deseado) / Prescaler = 256 - (4*10E6) * (0.05) / 1024 = 178

Si deseamos un delay de 50 ms
TCNT0 = 256 - (f_clk * t_deseado) / Prescaler = 256 - (4*10E6) * (0.05) / 1024 = 61

Si deseamos un delay de 100 ms
TCNT0 = 256 - (f_clk * t_deseado) / Prescaler = 256 - (4*10E6) * (0.1) / 1024 = -134 (IMPOSIBLE)

Por rapidez y comodidad usaremos un delay de 50 ms

Para lograr 100 ms podríamos usar esta configuración
f_clk = 1 MHz
prescaler = 1024
Tmax = 0.26 s = 262 ms
TCNT0 = 158 para obtener un
t_deseado = 0.100 s = 100 ms

Esta fue la configuración del system clock utilizada en el prelaboratorio
*/


// Encabezado
.include "M328PDEF.inc"
.cseg
.org    0x0000

// Definiciones
.equ PRESCALER = (1<<CS02) | (1<<CS00)				; Prescaler de TIMER0 (En este caso debe ser de 1024)
.equ TIMER_START = 158								; Valor inicial del Timer0
.def COUNTER_PORT = R20								; REGISTRO A MOSTRAR EN PUERTOS
.def SEVENSD_OUT = R21								; Registro temporal

// Lookup Table para Display de 7 Segmentos
.equ SEVENSD0 =	0b0111_0111
.equ SEVENSD1 =	0b0100_0001
.equ SEVENSD2 =	0b0011_1011
.equ SEVENSD3 =	0b0110_1011
.equ SEVENSD4 =	0b0100_1101
.equ SEVENSD5 =	0b0110_1110
.equ SEVENSD6 =	0b0111_1110
.equ SEVENSD7 =	0b0100_0011
.equ SEVENSD8 =	0b0111_1111
.equ SEVENSD9 =	0b0100_1111
.equ SEVENSDA =	0b0101_1111
.equ SEVENSDB =	0b0111_1100
.equ SEVENSDC =	0b0011_0110
.equ SEVENSDD =	0b0111_1001
.equ SEVENSDE =	0b0011_1110
.equ SEVENSDF =	0b0001_1110

// Configurar la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16

SETUP:
	// Activación de pines de entrada en el puerto B
    LDI     R16, 0x00
    OUT     DDRB, R16
    LDI     R16, 0xFF	// Desactivar salidas inicialmente
    OUT     PORTB, R16	// Por alguna razón no funciona si usamos algunos bits de PORTC como entradas y otros como salidas
	// Sin embargo, usar el puerto B solo para recibir entradas fue una solución rápida que terminó funcionando.
	
	// Activación de pines de salida en el puerto C
    LDI     R16, 0xFF	// Primeros cuatro bits como salidas y los primeros dos bits como entradas
    OUT     DDRC, R16
    LDI     R16, 0xF0	// Activar Pull-ups en entradas y desactivar salidas inicialmente
    OUT     PORTC, R16

	// Activación de pines de salida en el puerto D
    LDI     R16, 0xFF	// Primeros cuatro bits como salidas y los primeros dos bits como entradas
    OUT     DDRD, R16
    LDI     R16, 0x00	// Desactivar salidas inicialmente
    OUT     PORTD, R16

	// Configurar Prescaler Principal
	LDI		R16, (1 << CLKPCE)
	STS     CLKPR, R16          // Habilitar cambio de PRESCALER
    LDI     R16, 0x04			// CAMBIAR A 0X04
    STS     CLKPR, R16          // Configurar Prescaler a 1 Mhz

	// Inicializar timer0
    CALL    INIT_TMR0

	// Inicializar GPRs
	CLR		COUNTER_PORT
	CLR		SEVENSD_OUT


MAIN_LOOP:
    // Revisión de la bandera de Overflow en TIMER0
	IN      R16, TIFR0          // Leer registro de interrupción de TIMER0
    SBRS    R16, TOV0           // Salta si el bit 0 está "set" (TOV0 bit, Bandera de Overflow)
    RJMP    MAIN_LOOP           // Reiniciar loop
	
	// Si el reloj alcanza un desborde, se ejecuta el siguiente fragmento de código
	SBI     TIFR0, TOV0         // Limpiar bandera de "overflow" (No se limpia automáticamente)
	LDI     R16, TIMER_START    // Establecer el valor inicial del contador TCNT0
    OUT     TCNT0, R16          // Volver a cargar valor inicial en TCNT0 

	// LAB - Incrementar y decrementar el contador con dos botones
	IN		R17, PINB				// Leer el valor de PINC
	SBRS	R17, PB0
	INC		COUNTER_PORT
	SBRS	R17, PB1
	DEC		COUNTER_PORT			// ¡Y listo! Eso era todo el lab xd
	
	/*
	¿Por qué esto ya tiene antirrebote?
	Observe que este segmento de código se ejecuta únicamente cuando la bandera TOV0 está activa.
	Por lo tanto el TIMER0 cuenta hasta que se active la bandera y hasta ese entonces el valor de los bits puede cambiar.
	No es necesario revisar dos veces y hacer un delay de por medio.
	*/

	
	// PRELAB - Mostrar en LEDs
	// Mostrar Contador en PORTC
	ANDI	COUNTER_PORT, 0X0F		// Truncar el valor obtenido a 4 bits
	OUT		PORTC, COUNTER_PORT	// Mostrar el resultado en PORTC

	// Mostrar en display de 7 segmentos
	CALL	SEVEN_SEGMENT_DISPLAY
	OUT		PORTD, SEVENSD_OUT

	RJMP    MAIN_LOOP			// Regresar a Mainloop

// RUTINAS NO DE INTERRUPCIÓN

// Inicializar Timer0
INIT_TMR0:
    LDI     R16, PRESCALER				// Configurar un registro para setear las posiciones de CS01 y CS00
    OUT     TCCR0B, R16					// Setear prescaler del TIMER0 a 64 (CS01 = 1 y CS00 = 0)
    LDI     R16, TIMER_START			// Empezar el conteo con un valor de 100
    OUT     TCNT0, R16					// Cargar valor inicial en TCNT0
    RET

// Display de 7 segmentos
/*
En esta parte revisamos el valor del contador del puerto haciendo un compare con el valor que se va a mostrar en 
el display de 7 segmentos. Si el compare activa la bandera Z el programa regresará a MAINLOOP
*/
SEVEN_SEGMENT_DISPLAY:
	CLR		SEVENSD_OUT	
	
	// Revisar si el contador es 0	
	LDI		SEVENSD_OUT, SEVENSD0
	CPI		COUNTER_PORT, 0
	BREQ	END

	// Revisar si el contador es 1	
	LDI		SEVENSD_OUT, SEVENSD1
	CPI		COUNTER_PORT, 1
	BREQ	END

	// Revisar si el contador es 2	
	LDI		SEVENSD_OUT, SEVENSD2
	CPI		COUNTER_PORT, 2
	BREQ	END

	// Revisar si el contador es 3	
	LDI		SEVENSD_OUT, SEVENSD3
	CPI		COUNTER_PORT, 3
	BREQ	END

	// Revisar si el contador es 4
	LDI		SEVENSD_OUT, SEVENSD4
	CPI		COUNTER_PORT, 4
	BREQ	END

	// Revisar si el contador es 5	
	LDI		SEVENSD_OUT, SEVENSD5
	CPI		COUNTER_PORT, 5
	BREQ	END

	// Revisar si el contador es 6	
	LDI		SEVENSD_OUT, SEVENSD6
	CPI		COUNTER_PORT, 6
	BREQ	END

	// Revisar si el contador es 0	
	LDI		SEVENSD_OUT, SEVENSD7
	CPI		COUNTER_PORT, 7
	BREQ	END

	// Revisar si el contador es 8	
	LDI		SEVENSD_OUT, SEVENSD8
	CPI		COUNTER_PORT, 8
	BREQ	END

	// Revisar si el contador es 9	
	LDI		SEVENSD_OUT, SEVENSD9
	CPI		COUNTER_PORT, 9
	BREQ	END

	// Revisar si el contador es A	
	LDI		SEVENSD_OUT, SEVENSDA
	CPI		COUNTER_PORT, 10
	BREQ	END

	// Revisar si el contador es B	
	LDI		SEVENSD_OUT, SEVENSDB
	CPI		COUNTER_PORT, 11
	BREQ	END

	// Revisar si el contador es 12	
	LDI		SEVENSD_OUT, SEVENSDC
	CPI		COUNTER_PORT, 12
	BREQ	END

	// Revisar si el contador es 13	
	LDI		SEVENSD_OUT, SEVENSDD
	CPI		COUNTER_PORT, 13
	BREQ	END

	// Revisar si el contador es 14	
	LDI		SEVENSD_OUT, SEVENSDE
	CPI		COUNTER_PORT, 14
	BREQ	END

	// Revisar si el contador es 15	
	LDI		SEVENSD_OUT, SEVENSDF
	CPI		COUNTER_PORT, 15
	BREQ	END

	RET


END:
	RET
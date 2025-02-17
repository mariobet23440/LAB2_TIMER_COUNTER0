;
; Lab2_Timer_Counter0.asm
;
; Created: 14/02/2025 00:07:08
; Author : mario
; Link a Github: https://github.com/mariobet23440/LAB2_TIMER_COUNTER0
; Link a Yutub: https://youtu.be/qXeYrG3SbIA

/*
- HISTORIAL DE VERSIONES -

ENTREGA DE PRELAB: 14/02/2025 - 14:01
- Implementación del contador con TIMER0.
- Muestra el resultado del contador en los cuatro LEDs y en el display de 7 segmentos.

ENTREGA DE LAB: 14/02/2024 - 18:55
- Implementación de contador con entradas
*/


/*
POSTLAB
- El contador de LEDs incrementa cada vez que pasa un segundo.
- El contador del display de 7 segmentos cambia de valor con los botones
- Si el contador del display y el contador del LED tienen el mismo valor, 
  reiniciar el contador de botones, cambiando el estado de un LED
*/


// Encabezado
.include "M328PDEF.inc"
.cseg
.org    0x0000

// Definiciones
.equ PRESCALER = (1<<CS02) | (1<<CS00)				; Prescaler de TIMER0 (En este caso debe ser de 1024)
.equ TIMER_START = 158								; Valor inicial del Timer0 (100 ms)
.def COUNTER_BUTTON = R20							; Contador de botones
.def COUNTER_TEMP = R22								; Contador temporal (Para contador de segundos)
.def COUNTER_SECONDS = R23
.def SEVENSD_OUT = R21								; Registro temporal
.def COUNTER_COUNTER = R24							; Contador adicional

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
    STS     CLKPR, R16          // Configurar Prescaler a 1 MHz

	// Inicializar timer0
    CALL    INIT_TMR0

	// Inicializar GPRs
	CLR		COUNTER_TEMP
	CLR		COUNTER_SECONDS
	CLR		COUNTER_BUTTON
	CLR		SEVENSD_OUT
	CLR		COUNTER_COUNTER

MAIN_LOOP:
    // Revisión de la bandera de Overflow en TIMER0
	IN      R16, TIFR0          // Leer registro de interrupción de TIMER0
    SBRS    R16, TOV0           // Salta si el bit 0 está "set" (TOV0 bit, Bandera de Overflow)
    RJMP    MAIN_LOOP           // Reiniciar loop
	
	// Si el reloj alcanza un desborde, se ejecuta el siguiente fragmento de código
	SBI     TIFR0, TOV0         // Limpiar bandera de "overflow" (No se limpia automáticamente)
	LDI     R16, TIMER_START    // Establecer el valor inicial del contador TCNT0
    OUT     TCNT0, R16          // Volver a cargar valor inicial en TCNT0 

	// Contador de Botones
	IN		R17, PINB				// Leer el valor de PINC
	SBRS	R17, PB0
	INC		COUNTER_BUTTON
	SBRS	R17, PB1
	DEC		COUNTER_BUTTON			// ¡Y listo! Eso era todo el lab xd
	ANDI	COUNTER_BUTTON, 0X0F

	// Mostrar en display de 7 segmentos
	CALL	SEVEN_SEGMENT_DISPLAY
	OUT		PORTD, SEVENSD_OUT

	// Incrementar el valor del contador de segundos
	INC		COUNTER_TEMP
	ANDI	COUNTER_TEMP, 0X0F
	CPI     COUNTER_TEMP, 10			; Si COUNTER_TEMP alcanza 10 habrá transcurrido 1s. Levantamos Z
	BREQ    CONTADOR_SEGUNDOS           ; Si COUNTER_TEMP = 10 ir a CONTADOR_SEGUNDOS
	RJMP    MAIN_LOOP                   ; Vuelve al loop principal

// RUTINAS NO DE INTERRUPCIÓN

// Contador de Segundos
CONTADOR_SEGUNDOS: 
	CLR		COUNTER_TEMP
	OUT     PORTC, COUNTER_SECONDS  // Si no se hace un reset, se muestra el valor del contador
	
	INC     COUNTER_SECONDS			// Incrementar el valor del contador de segundos
    ANDI    COUNTER_SECONDS, 0x1F	// Aplicar una máscara de 5 bits
	MOV		R16, COUNTER_SECONDS	// Copiamos el registro en R16
	ANDI	R16, 0X0F				// Truncamos el valor a 4 bits antes de la comparación

	MOV		R17, COUNTER_BUTTON
    SUB     R17, R16				// Si el valor del contador de segundos es mayor que el de botones (Y la resta es negativa, hacer un reset)
    BRMI    RESET_CONTADOR
	
	
    RJMP    MAIN_LOOP

RESET_CONTADOR:
	CLR		COUNTER_SECONDS
	INC		COUNTER_COUNTER
	MOV		R16, COUNTER_COUNTER
	ANDI	R16, 0X01
	SWAP	R16
	OR		COUNTER_SECONDS, R16
	RJMP	MAIN_LOOP



// Inicializar Timer0
INIT_TMR0:
    LDI     R16, PRESCALER				// Configurar un registro para setear las posiciones de CS01 y CS00
    OUT     TCCR0B, R16					// Setear prescaler del TIMER0 a 64 (CS01 = 1 y CS00 = 0)
    LDI     R16, TIMER_START			// Empezar el conteo con un valor de 158
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
	CPI		COUNTER_BUTTON, 0
	BREQ	END

	// Revisar si el contador es 1	
	LDI		SEVENSD_OUT, SEVENSD1
	CPI		COUNTER_BUTTON, 1
	BREQ	END

	// Revisar si el contador es 2	
	LDI		SEVENSD_OUT, SEVENSD2
	CPI		COUNTER_BUTTON, 2
	BREQ	END

	// Revisar si el contador es 3	
	LDI		SEVENSD_OUT, SEVENSD3
	CPI		COUNTER_BUTTON, 3
	BREQ	END

	// Revisar si el contador es 4
	LDI		SEVENSD_OUT, SEVENSD4
	CPI		COUNTER_BUTTON, 4
	BREQ	END

	// Revisar si el contador es 5	
	LDI		SEVENSD_OUT, SEVENSD5
	CPI		COUNTER_BUTTON, 5
	BREQ	END

	// Revisar si el contador es 6	
	LDI		SEVENSD_OUT, SEVENSD6
	CPI		COUNTER_BUTTON, 6
	BREQ	END

	// Revisar si el contador es 0	
	LDI		SEVENSD_OUT, SEVENSD7
	CPI		COUNTER_BUTTON, 7
	BREQ	END

	// Revisar si el contador es 8	
	LDI		SEVENSD_OUT, SEVENSD8
	CPI		COUNTER_BUTTON, 8
	BREQ	END

	// Revisar si el contador es 9	
	LDI		SEVENSD_OUT, SEVENSD9
	CPI		COUNTER_BUTTON, 9
	BREQ	END

	// Revisar si el contador es A	
	LDI		SEVENSD_OUT, SEVENSDA
	CPI		COUNTER_BUTTON, 10
	BREQ	END

	// Revisar si el contador es B	
	LDI		SEVENSD_OUT, SEVENSDB
	CPI		COUNTER_BUTTON, 11
	BREQ	END

	// Revisar si el contador es 12	
	LDI		SEVENSD_OUT, SEVENSDC
	CPI		COUNTER_BUTTON, 12
	BREQ	END

	// Revisar si el contador es 13	
	LDI		SEVENSD_OUT, SEVENSDD
	CPI		COUNTER_BUTTON, 13
	BREQ	END

	// Revisar si el contador es 14	
	LDI		SEVENSD_OUT, SEVENSDE
	CPI		COUNTER_BUTTON, 14
	BREQ	END

	// Revisar si el contador es 15	
	LDI		SEVENSD_OUT, SEVENSDF
	CPI		COUNTER_BUTTON, 15
	BREQ	END

	RET


END:
	RET
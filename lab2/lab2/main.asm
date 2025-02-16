
;Universidad del Valle de Guatemala
;Jose Rodrigo Oliveros Gonzalez

.include "M328PDEF.INC" 
.cseg
.org 0x00 

;CONFIGURACIÓN PILA

	LDI		R16, LOW(RAMEND) 
	OUT		SPL, R16
	LDI		R16, HIGH(RAMEND) 
	OUT		SPH, R16
;CONFIGURACIÓN
SETUP:
	; Clock en 2MHz
	LDI		R16, 0b1000_0000 
	STS		CLKPR, R16 ; PRESCALER
	LDI		R16, 0b0000_0011
	STS		CLKPR, R16  ;Divisor entre 8 para 2MHz	
	
	; TIMER0
	CALL	TIMERINIT ; Inicializar el Timer0

	; Entradas (PORTB a Buttons)

	LDI		R17, 0x00
	OUT		DDRB, R17 ; PORTB ENTRADAS
	OUT		PORTB, R16 ; PULL-UP

	; Salidas (PORTD (7 segmentos) y PORTC a (LEDS))

	LDI		R16, 0xFF
	OUT		DDRD, R16 ; PORTD SALIDAS
	OUT		DDRC, R16 ; PORTD SALIDAS
	
    ; Desactivar comunicación UART
    LDI		R16,	0x00
    STS		UCSR0B,	R16			; Desactivar TX y RX

	;Estados previos
	LDI		R17, 0xFF 

	;Glosario
	;
	; R18 Registro de estado de puerto b
	; R19 Control para Timer0
	; R20 Control para 7seg
	; R21 Control de 1s
	; R22 ;LED
	; R23 Registro para combinación

; MAIN
MAIN:

	; Leo el valor del registro TIFR0 para verificar si el Timer0 ha generado un overflow.	
	IN		R16, TIFR0 
	CPI		R16, (1<<TOV0) ; Comparo si la bandera de overflow (TOV0) está activada.
	BRNE	CHECK_7SEGM ; Si no hay overflow, salto a verificar el estado del 7 segmentos.

	; Contador de 4 bits
	INC		R21 ; Incremento el contador R21, cuenta de milisegundos
	CPI		R21, 10 ; Comparo si R21 ha llegado a 10 equivalente a 1 segundo.
	BRNE	RESETTIMER0 ; Si no ha llegado a 10, reincio el Timer0.

	; Si ya ha pasado 1 segundo
	LDI		R21, 0x00 ; Reinicio el contador R21 de milisegundos
	INC		R19 ; Incremento el contador (R19), que lleva la cuenta de los segundos.
	ANDI	R19, 0x0F ; Limpio el nibble más alto de R19 para mantener solo los 4 bits menos significativos.
	MOV		R23, R22 ; Copio el valor de la alerta LED (R22) al registro de combinación (R23).
	OR		R23, R19 ; Combino la alerta LED con el contador binario (R19) para desplegarlo correctamente en el puerto.
	OUT		PORTC, R23 ; Muestro la combinación en PORTC (LEDs).

RESETTIMER0:
	CALL	TIMERRESET ; Llamo a la subrutina para reiniciar el Timer0.
	SBI		TIFR0, TOV0 ; Borro la bandera de overflow (TOV0) en el registro TIFR0.

	; Contador 7 segmentos
CHECK_7SEGM:
	; Antirrebote
	IN		R18, PINB ; Leo el estado actual de los botones en PORTB.
	CP		R17, R18 ; Comparo el estado actual (R18) con el estado previo (R17).
	BREQ	MOD_7SEGM ; Si no hay cambios, salto a MOD_7SEGM para actualizar el 7 segmentos.
	CALL	ANTIRREBOTE ; Llamo a la subrutina para evitar falsos positivos.
	IN		R18, PINB ; Vuelvo a leer el estado de los botones 
	CP		R17, R18 ; Comparo el estado actual con el estado previo 
	BREQ	MAIN ; Si no hay cambios, regreso 

	; Si hubo cambios
	MOV		R17, R18 ; Actualizo el estado previo (R17) con el estado actual (R18).
	CALL	CONTROL_7SEGM ; Llamo a la subrutina para controlar el contador del 7 segmentos.

	ANDI	R20, 0x0F ; Limpio el nibble más alto del contador R20 para mantener solo los 4 bits menos significativos.

MOD_7SEGM:
	LDI		ZH, HIGH(TABLA7SEGM<<1) ;  Parte alta de la dirección de la tabla de 7 segmentos.
	LDI		ZL, LOW(TABLA7SEGM<<1) ; Parte baja de la dirección de la tabla de 7 segmentos.
	ADD		ZL, R20 ; Añado el valor del contador R20 a Z para obtener la posición correcta en la tabla.
	LPM		R16, Z ; Leo el valor de la tabla de 7 segmentos
	OUT		PORTD, R16 ; Muestro el valor en el  7 segmentos (PORTD).

CP_CONTADORES:
	CP		R19, R20 ; Comparo el contador (R19) con el contador del 7 segmentos (R20).
	BRNE	MAIN ; Si no son iguales, regreso al inicio del loop.

	; Si son iguales
	LDI		R19, 0x00 ; Reinicio (R19).
	LDI		R21, 0x00 ; Reinicio el contador del Timer0 (R21).
	SWAP	R22 ; Intercambio los nibbles de R22 (alerta LED).
	INC		R22 ; Incremento el registro de alerta LED (R22).
	ANDI	R22, 0x01 ; Limpio todos los bits excepto el primero.
	SWAP	R22 ; Devuelvo el nibble alto a su posición original. (LED ya tratado con alerta)

	RJMP MAIN 

; Subrutinas (no interrupción)

; Subrutina para inicializar el Timer0
TIMERINIT:
	LDI		R16, 0b0000_0101 ; Configuro el prescaler del Timer0 a 1024.
	OUT		TCCR0B, R16 ; Escribo el valor en el registro TCCR0B.
TIMERRESET:
	; Cargo el valor 61 en TCNT0 para un overflow ~100ms.
	LDI		R16, 61 
	OUT		TCNT0, R16 ; Escribo el valor en el registro TCNT0.
	RET 

; Subrutina de antirrebote
ANTIRREBOTE:
	LDI		R16, 100 ; Configuro un retardo de 100 ciclos.
DELAY:
	DEC		R16 ; Decremento R16.
	CPI		R16, 0x00 ; Comparo R16 con 0.
	BRNE	DELAY ; Si R16 no es 0, repito.
	RET 

; Subrutina para controlar el contador del 7 segmentos
CONTROL_7SEGM:
AUMENTAR:
	SBRC	R18, PB0 ; Verifico si el botón de aumentar (PB0) está presionado.
	RJMP	DISMINUIR ; Si no está presionado, salto a DISMINUIR.
	INC		R20 ; Incremento el contador del 7 segmentos (R20).

DISMINUIR:
	SBRC	R18, PB1 ; Verifico si el botón de disminuir (PB1) está presionado.
	RET		; Si no está presionado, retorno
	DEC		R20 ; Disminuyo el contador del 7 segmentos (R20).
	RET 

; Tabla de valores para el display de 7 segmentos
TABLA7SEGM: .db 0x3F,0x06,0x3C,0x4E,0x66,0x6D,0x7B,0x07,0x7F,0x67,0x77,0x7C,0x39,0x4E,0x79,0x71

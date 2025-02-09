
;
; Antirrebote.asm
;
; Created: 31/01/2025 18:20:59
; Author : rodri
;
;ENCABEZADO
.include "M328PDEF.inc"
.cseg
.org 0x0000

;CONFIGURACION DE PILA
LDI		R16, LOW(RAMEND) ;CARGAR 0XFF A R16
OUT		SPL, R16		;CARGAR 0FF A SPL
LDI		R17, HIGH(RAMEND) ; CARGAR 0X08
OUT		SPH, R16			; CARGAR 0X08 A SPH

;CONFIGURACION DE MCU
SETUP:
	;CONFIGURAR PUERTOB COMO ENTRADA CON PULL-UPS HABILITADOS
	LDI		R16, 0x00
	OUT		DDRB,R16 ; Seteamos todo el puerto B como entrada
	LDI		R16, 0xFF
	OUT		PORTB, R16; Habilitamos pull-ups en todo el puerto B
	;cuando este apagado es 1 y encendido es 0

	
	; Desactivar comunicación UART
	LDI		R16, 0x00
	STS		UCSR0B, R16  ; APAGO TX Y RX
	STS		UCSR0C, R16  ; LIMPIO CONFIGURACIÓN DEL UART

	; Configurar Puerto C y D como salida
	LDI		R16, 0xFF
	OUT		DDRC, R16  ; TODO EL PUERTO C COMO SALIDA
	LDI		R16, 0xFF
	OUT		DDRD, R16  ; TODO EL PUERTO D COMO SALIDA

	; Asegurar que PD0 y PD1 inicien en bajo
	LDI		R16, 0x00
	OUT		PORTD, R16  ; APAGO TODAS LAS SALIDAS DEL PUERTO D



	;Guardar estado actual de los botones en R17
	LDI R17, 0xFF ;ESTADO ACTUAL
	LDI R20, 0x00; contador1
	LDI R21, 0x00; contador2

	;GLOSARIO
	;R17 ESTADO ACTUAL
	;R16 USO MULTIPLE, usualmente lectura

;LOOP PRINCIPAL
MAIN:
	;Antirrebote
	IN		R16, PINB	;leer puerto B
	CP		R17, R16	; comparar estado viejo con actual
	BREQ	MAIN		;si son iguales regreso al main
	CALL	DELAY
	IN		R16, PINB	;leer puerto B
	CP		R17, R16	; comparar estado viejo con actual
	BREQ	MAIN		;si son iguales regreso al main
	;si no lo son
	MOV		R17, R16 ;guardo estado actual de botones en R17
	;CONTADOR
	CALL	CONTADOR1
	CALL	CONTADOR2
	RJMP	MAIN	

;SUBRUTINAS (NO DE INTERRUPCIÓN)
DELAY:
	LDI		R19, 100	;comenzamos con el delay
CONTEO:
	DEC		R19
	CPI		R19, 0x00
	BRNE	CONTEO
	RET

CONTADOR1:

AUMENTAR:
	SBRC	R16, PB0 ;REVISANDO SI EL BIT 0 ESTA "APACHADO" = 0 LOGICO
	RJMP	REDUCIR
	INC		R20 ; Si esta presionado aumentamos
	OUT		PORTC, R20
REDUCIR:
	SBRC	R16, PB1 ;REVISANDO SI EL BIT 0 ESTA "APACHADO" = 0 LOGICO
	RET
	DEC		R20 ; Si esta presionado disminuimos
	OUT		PORTC, R20
	RET

CONTADOR2:
AUMENTAR2:
	SBRC	R16, PB3 ;REVISANDO SI EL BIT 0 ESTA "APACHADO" = 0 LOGICO
	RJMP	REDUCIR2
	INC		R21 ; Si esta presionado aumentamos
	OUT		PORTD, R21
REDUCIR2:
	SBRC	R16, PB4 ;REVISANDO SI EL BIT 0 ESTA "APACHADO" = 0 LOGICO
	RET
	DEC		R21 ; Si esta presionado disminuimos
	OUT		PORTD, R21
	RET
;SUBRUTINAS DE INTERRUPCIÓN
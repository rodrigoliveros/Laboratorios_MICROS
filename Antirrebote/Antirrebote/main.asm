
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

	; Clock en 1MHz
	LDI R16, 0b1000_0000 
	STS CLKPR, R16 ; Habilitar prescaler (STS por la memoria en donde esta CLKPR)
	LDI R16, 0b0000_0100
	STS CLKPR, R16  ; 0100 es Divisor entre 16

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

	; Configurar Puerto C
	LDI		R16, 0b00101111 ; PC5 (carry) y PC0-PC3 (contador 1) como salidas, PC4 (botón) como entrada
	OUT		DDRC, R16  ; TODO EL PUERTO C COMO SALIDA
	LDI		R16, 0b00010000 ; Habilitar pull-up en PC4 (botón)
	OUT		PORTC, R16

	;Configurar Puerto D
	LDI		R16, 0b11111111 ; PD4-PD7 (resultado) y PD0-PD3 (contador 2) como salidas
	OUT		DDRD, R16
	LDI		R16, 0b00000000 ; Apagar todas las salidas del Puerto D inicialmente
	OUT		PORTD, R16

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
	BREQ	CHECK_SUMA		;si son iguales revisar el boton de suma
	CALL	DELAY
	IN		R16, PINB	;leer puerto B
	CP		R17, R16	; comparar estado viejo con actual
	BREQ	CHECK_SUMA		;si son iguales revisar el boton de suma
	;si no lo son
	MOV		R17, R16 ;guardo estado actual de botones en R17
	;CONTADOR
	CALL	CONTADOR1
	CALL	CONTADOR2

CHECK_SUMA:
	; Verificar si el botón de suma (PC4) está presionado
	SBIC PINC, PC4 ; Saltar si PC4 está en alto (no presionado)
	RJMP MAIN      ; Si no está presionado, volver al MAIN

	; Si esta precionado llamar a la subrutina de suma
	CALL SUMA
	RJMP MAIN

;SUBRUTINAS (NO DE INTERRUPCIÓN)
DELAY:
	LDI		R19, 255	;comenzamos con el delay
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

SUMA:
	; Leer valores de PC0-PC3 (contador 1) y PD0-PD3 (contador 2)
	IN		R22, PINC  ; Leer PC0-PC3
	IN		R23, PIND  ; Leer PD0-PD3

	; Enmascarar bits no deseados
	ANDI	R22, 0b00001111 ; Solo PC0-PC3
	ANDI	R23, 0b00001111 ; Solo PD0-PD3

	; Sumar los valores
	ADD		R22, R23  ; Sumar contador 1 y contador 2
	MOV		R24, R22  ; Guardar resultado en R24

	; Mostrar resultado en PD4-PD7
	SWAP	R24      ; Mover el nibble bajo al nibble alto
	ANDI	R24, 0b11110000 ; Asegurar que solo PD4-PD7 se modifiquen
	OUT		PORTD, R24 ; Mostrar resultado en PD4-PD7

	; Verificar carry
	BRCC	NO_CARRY ; Si no hay carry, saltar
	SBI		PORTC, PC5 ; Encender LED de carry en PC5
	RET

NO_CARRY:
	CBI		PORTC, PC5 ; Apagar LED de carry en PC5
	RET
;SUBRUTINAS DE INTERRUPCIÓN
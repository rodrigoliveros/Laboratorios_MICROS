
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
	LDI		R16,	0b00101111	; PC5 (carry) y PC0-PC3 (resultado) como salidas, PC4 (botón) como entrada
	OUT		DDRC,	R16			; Configura PORTC
	LDI		R16,	0b00010000	; Habilitar pull-up en PC4 (botón)
	OUT		PORTC,	R16


	;Configurar Puerto D
	LDI		R16, 0b11111111 ; PD4-PD7 (resultado) y PD0-PD3 (contador 2) como salidas
	OUT		DDRD, R16
	LDI		R16, 0b00000000 ; Apagar todas las salidas del Puerto D inicialmente
	OUT		PORTD, R16

	; Asegurar que PD0 y PD1 inicien en bajo
	LDI		R16, 0x00
	OUT		PORTD, R16  ; APAGO TODAS LAS SALIDAS DEL PUERTO D
	
	; Registro para monitoreo de estados previos
	LDI		R18,	0xFF
	
	; Registros para Contadores
	LDI		R19,	0x00		; Contador 1
	LDI		R20,	0x00		; Contador 2
	LDI		R21,	0x00		; OR de 1 y 2
	LDI		R22,	0x00		; Suma de 1 y 2

;LOOP PRINCIPAL
MAIN:
	;Antirrebote
	
	IN		R16, PINB	;leer puerto B
	CP		R16, R18	; comparar estado viejo con actual
	BREQ	MAIN		;si son iguales revisar el boton de suma
	CALL	DELAY
	IN		R16, PINB	;leer puerto B
	CP		R16, R18	; comparar estado viejo con actual
	BREQ	MAIN		;si son iguales revisar el boton de suma
	;si no lo son
	MOV		R18, R16 ;guardo estado actual de botones en R17
	;CONTADOR
	CALL	CONTADORES
	CALL	SUM_UP
	CALL	CHECK_SUMA
	RJMP	MAIN


;SUBRUTINAS (NO DE INTERRUPCIÓN)
DELAY:
	LDI		R19, 255	;comenzamos con el delay
CONTEO:
	DEC		R19
	CPI		R19, 0x00
	BRNE	CONTEO
	RET

CONTADORES:

AUMENTAR:
	SBRC	R16, PB0 ;REVISANDO SI EL BIT 0 ESTA "APACHADO" = 0 LOGICO
	RJMP	REDUCIR
	INC		R20 ; Si esta presionado aumentamos
REDUCIR:
	SBRC	R16, PB1 ;REVISANDO SI EL BIT 0 ESTA "APACHADO" = 0 LOGICO
	DEC		R20 ; Si esta presionado disminuimos

AUMENTAR2:
	SBRC	R16, PB3 ;REVISANDO SI EL BIT 0 ESTA "APACHADO" = 0 LOGICO
	RJMP	REDUCIR2
	INC		R21 ; Si esta presionado aumentamos
REDUCIR2:
	SBRC	R16, PB4 ;REVISANDO SI EL BIT 0 ESTA "APACHADO" = 0 LOGICO
	RET
	DEC		R21 ; Si esta presionado disminuimos
	RET

SUM_UP:
	ANDI	R19, 0x0F
	ANDI	R20, 0x0F
	SWAP	R20
	MOV		R21, R19
	OR		R21, R20
	SWAP	R20
	OUT		PORTD, R21
	RET

CHECK_SUMA:
	; Verificar si el botón de suma (PC4) está presionado
	SBIC	PINC, PC4 ; Saltar si PC4 está en alto (no presionado)
	RET     ; Si no está presionado, volver al MAIN
	CALL	DELAY
	SBIC	PINC, PC4 ; Saltar si PC4 está en alto (no presionado)
	RET     ; Si no está presionado, volver al MAIN
	; Si esta precionado llamar a la subrutina de suma
	MOV		R22, R19
	ADD		R22, R20

	BRCC	NO_CARRY
	SBI		PORTC, PC5
	RJMP	SHOW

NO_CARRY:
	CBI		PORTC, PC5

SHOW:
	ANDI R22, 0x0F
	OUT PORTC, R22
	RET
;SUBRUTINAS DE INTERRUPCIÓN
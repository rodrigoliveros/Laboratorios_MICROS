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

;CONFIGURACION

SETUP:
    ; Clock en 1MHz
    LDI		R16,	0b1000_0000 
    STS		CLKPR,	R16			; Habilitar prescaler (STS por la memoria en donde esta CLKPR)
    LDI		R16,	0b0000_0100
    STS		CLKPR,	R16			; Divisor entre 16

    ; Desactivar comunicación UART
    LDI		R16,	0x00
    STS		UCSR0B,	R16			; Desactivar TX y RX
    STS		UCSR0C,	R16			; Limpiar configuración del UART

    ; Salidas 
    LDI		R16,	0b00101111	; PC5 (carry) y PC0-PC3 (resultados) como salidas, PC4 (botón) como entrada
    OUT		DDRC,	R16			; Configura PORTC
    LDI		R16,	0b00010000	; Habilitar pull-up en PC4 (botón)
    OUT		PORTC,	R16

    LDI		R16,	0xFF
    OUT		DDRD,	R16			; Configurar PORTD a Salida
    
    ; Entradas 
    LDI		R17,	0x00
    OUT		DDRB,	R17			
    OUT		PORTB,	R16			; Configurar todos Pull-Up

    ; Glosario
    LDI		R18,	0xFF		; Estados previos
    LDI		R19,	0x00		; Contador 1
    LDI		R20,	0x00		; Contador 2
    LDI		R21,	0x00		; OR de 1 y 2
    LDI		R22,	0x00		; Suma de 1 y 2
    
; MAIN

MAIN:
    ; Antirrebote
    IN		R16,	PINB
    CP		R16,	R18		; Comparo los estados actual y previo 
    BREQ	BSUMA	; Si no han cambiado, verifico el botón de suma
    CALL	DELAY
    IN		R16,	PINB
    CP		R16,	R18		; Comparamos nuevamente
    BREQ	BSUMA	; Si no han cambiado, verifico el botón de suma
    ; Si cambiaron
    MOV		R18,	R16		; Guardamos estado actual
    
    CALL	CONTADORES		
    
    CALL	SUM_UP		; Combina los contadores 

BSUMA:
    ; Verificar si el botón de suma (PC4) está presionado
    SBIC	PINC,	PC4		; Saltar si PC4 está en alto (no presionado)
    RJMP	MAIN			; Si no está presionado, vuelvo al loop

    ; Delay para antirrebote
    CALL	DELAY

    ; Verificar nuevamente el estado del botón
    SBIC	PINC,	PC4		; Saltar si PC4 está en alto (no presionado)
    RJMP	MAIN			; Si no está presionado, vuelvo al loop

    ; Llamar a la subrutina de suma
    CALL	SUMAS

    RJMP	MAIN			; Al terminar vuelve al loop

; Subrutinas

DELAY:
    LDI		R17,	100		
CONTEO:
    DEC		R17				
    CPI		R17,	0x00	; Compara Contador con 0
    BRNE	CONTEO			
    RET

CONTADORES:
AUMENTAR1:
    SBRC	R16,	PB0		; Estado de aumentar 
    RJMP	REDUCIR1	; De no estar presionado prosigo
    INC		R19				; Aumento contador1

REDUCIR1:
    SBRC	R16,	PB1		; Estado de reducir
    RJMP	AUMENTAR2		; De no estar presionado prosigo
    DEC		R19				; Disminuyo contador1

AUMENTAR2:
    SBRC	R16,	PB3		; Estado de aumentar 
    RJMP	REDUCIR2	; De no estar presionado prosigo
    INC		R20				; Aumento contador2
REDUCIR2:
    SBRC	R16,	PB4		; Estado de reducir 
    RET						; De no estar presionado prosigo
    DEC		R20				; Disminuyo contador1

    RET						; Al terminar, vuelvo al CALL

SUM_UP:
    ANDI	R19,	0X0F	; Modificar ambos contadores 
    ANDI	R20,	0X0F
    SWAP	R20				; Cambiar nibble bajo por alto
    MOV		R21,	R19		
    OR		R21,	R20		; Combinar registros
    SWAP	R20				; Regresar a su estado original
    OUT		PORTD,	R21		
    RET						

SUMAS:
    ; Limpiar el bit de carry antes de la suma
    CLC						; Clear Carry Flag

    ; Realizar la suma
    MOV		R22,	R19		
    ADD		R22,	R20		; Sumar R19 y R20 en R22

    ; Carry
    BRCC	NO_CARRY		
    SBI		PORTC,	PC5		; Encender LED de carry en PC5
    RJMP	SHOW

NO_CARRY:
    CBI		PORTC,	PC5		; Apagar LED de carry en PC5

SHOW:
    ANDI	R22,	0x0F	; Asegurar que solo se usen los 4 bits bajos
    OUT		PORTC,	R22		; Mostrar el resultado en PORTC (PC0-PC3)

    RET						; Al terminar, vuelvo al CALL
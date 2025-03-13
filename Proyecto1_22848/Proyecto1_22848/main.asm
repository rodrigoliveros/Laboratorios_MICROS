;
; Proyecto1_22848.asm
;
; Created: 10/03/2025 10:52:25
; Author : rodri

; Definiciones de registros y constantes
.include "M328PDEF.inc"  ; Incluir definiciones para el ATmega328P

.equ	T0VALUE		=  216
.equ	MODOS		=  8
.def	MODO		=  R20
.def	CONTADOR	=  R21

; Vectores de interrupción

.org 0x0000
    RJMP        SETUP           ; Reset
.org PCI1addr					; Vector de interrupción para PCINT1 (Puerto C)
    RJMP        PCINT1_ISR      ; Saltar a la rutina de interrupción
.org OVF0addr					; Vector de interrupción para Timer0 Overflow
    RJMP        TIMER0_OVF_ISR  ; Saltar a la rutina de interrupción del Timer0

; Rutina de reset
SETUP:
    ; Configurar el stack pointer
    LDI         R16, HIGH(RAMEND)
    OUT         SPH, R16
    LDI         R16, LOW(RAMEND)
    OUT         SPL, R16

    ; Configurar Puerto C como entrada (PC0-PC3) y salida (PC4-PC5)(LEDs)
    LDI         R16, 0xF0       ; PC0-PC3 como entrada y PC4-PC5 como salida
    OUT         DDRC, R16
	
    ; Habilitar pull-ups internos en PC0-PC2
    LDI         R16, (1 << PC0) | (1 << PC1) | (1 << PC2) 
    OUT         PORTC, R16
	
    ; Configurar interrupciones on-change para PC0-PC2
    LDI         R16, (1 << PCINT8) | (1 << PCINT9) | (1 << PCINT10)
    STS         PCMSK1, R16

    ; Habilitar interrupciones de cambio en Puerto C
    LDI         R16, (1 << PCIE1)
    STS         PCICR, R16

	; Configurar Puerto D como salida (PORTD (7 segmentos))
	LDI			R16, 0xFF
	OUT			DDRD, R16 ; PORTD SALIDAS
	
    ; Desactivar comunicación UART
    LDI			R16,	0x00
    STS			UCSR0B,	R16			; Desactivar TX y RX

    ; Configurar Puerto B como salida (Transistores y Alarma)
    LDI         R16, 0xFF       ; PB0-PB4
    OUT         DDRB, R16

    ; Configurar Timer0 para antirrebote (20 ms)
    LDI         R16, (1 << CS02) | (1 << CS00) ; Prescaler de 1024
    OUT         TCCR0B, R16
    LDI         R16, (1 << TOIE0)              ; Habilitar interrupción por overflow
    STS         TIMSK0, R16
	LDI			R16, T0VALUE
	OUT			TCNT0, R16
	
	; Tabla de conversión para display de 7 segmentos (cátodo común)
	TABLA7SEGM: .db 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F

	;Inicializar variables

	CLR			MODO
	CLR			CONTADOR


    ; Habilitar interrupciones globales
    SEI

;MAIN
MAIN_LOOP:
	
	SBI			PORTB, PB0
	OUT			PORTD, CONTADOR
	CPI			MODO, 0
	BREQ		S_HORA
	CPI			MODO, 1
	BREQ		S_FECHA
	CPI			MODO, 2
	BREQ		M_HORA_MIN
	CPI			MODO, 3
	BREQ		M_HORA_HOR
	CPI			MODO, 4
	BREQ		M_FECHA_MES
	CPI			MODO, 5
	BREQ		M_FECHA_DIA
	CPI			MODO, 6
	BREQ		M_ALARM_MIN
	CPI			MODO, 7
	BREQ		M_ALARM_HORA


;Subrutinas de estado
S_HORA:							; LEDS |-|0|
	LDI			CONTADOR, 0x3F
	SBI			PORTC, PC5 
	CBI			PORTC, PC4
	RJMP		MAIN_LOOP
S_FECHA:						; LEDS |0|-|
	LDI			CONTADOR, 0x06
	CBI			PORTC, PC5
	SBI			PORTC, PC4
	RJMP		MAIN_LOOP
M_HORA_MIN:						; LEDS |-|0|
	LDI			CONTADOR, 0x5B		
	SBI			PORTC, PC5
	CBI			PORTC, PC4
	RJMP		MAIN_LOOP
M_HORA_HOR:						; LEDS |-|0|
	LDI			CONTADOR, 0x4F
	SBI			PORTC, PC5
	CBI			PORTC, PC4
	RJMP		MAIN_LOOP
M_FECHA_MES:					; LEDS |0|-|
	LDI			CONTADOR, 0x66
	CBI			PORTC, PC5
	SBI			PORTC, PC4
	RJMP		MAIN_LOOP
M_FECHA_DIA:					; LEDS |0|-|
	LDI			CONTADOR, 0x6D
	CBI			PORTC, PC5
	SBI			PORTC, PC4
	RJMP		MAIN_LOOP	
M_ALARM_MIN:					; LEDS |0|0|
	LDI			CONTADOR, 0x7D
	SBI			PORTC, PC5
	SBI			PORTC, PC4
	RJMP		MAIN_LOOP
M_ALARM_HORA:					; LEDS |0|0|
	LDI			CONTADOR, 0x07
	SBI			PORTC, PC5
	SBI			PORTC, PC4
	RJMP		MAIN_LOOP	   
; RUTINAS DE INTERRUPCIÓN

; Rutina de interrupción para PCINT1
PCINT1_ISR:
    ; Guardar el estado de los registros
    PUSH        R16
    IN          R16, SREG
    PUSH        R16
	; Verificar si estamos en el modo máximo
	SBIS		PINC, PC0	; Verifico si el pin modo esta presionado "0"
	INC			MODO		
	LDI			R16, MODOS	; Modos es el valor máximo de modos
	CPSE		MODO, R16	; Si no son iguales ejecuta la siguiente linea
	RJMP		PC+2		; Salta dos lineas
	CLR			MODO
	; Revisar en que modo estamos
	CPI			MODO, 0
	BREQ		MODO0_ISR
	CPI			MODO, 1
	BREQ		MODO1_ISR
	CPI			MODO, 2
	BREQ		MODO2_ISR
	CPI			MODO, 3
	BREQ		MODO3_ISR
	CPI			MODO, 4
	BREQ		MODO4_ISR
	CPI			MODO, 5
	BREQ		MODO5_ISR
	CPI			MODO, 6
	BREQ		MODO6_ISR
	CPI			MODO, 7
	BREQ		MODO7_ISR
	RJMP		EXIT_PDINT1_ISR
    ; Restaurar el estado de los registros
	MODO0_ISR:
		//Relacionado con mostrar hora
		RJMP EXIT_PDINT1_ISR
	MODO1_ISR:
		//Relacionado con mostrar fecha
		RJMP EXIT_PDINT1_ISR
	MODO2_ISR:
		//Relacionado con configurar minutos
		RJMP EXIT_PDINT1_ISR
	MODO3_ISR:
		//Relacionado con configurar hora
		RJMP EXIT_PDINT1_ISR
	MODO4_ISR:
		//Relacionado con configurar meses
		RJMP EXIT_PDINT1_ISR
	MODO5_ISR:
		//Relacionado con configurar dias
		RJMP EXIT_PDINT1_ISR
	MODO6_ISR:
		//Relacionado con alarma minutos
		RJMP EXIT_PDINT1_ISR
	MODO7_ISR:
		//Relacionado con alarma horas
		RJMP EXIT_PDINT1_ISR
	EXIT_PDINT1_ISR:
    POP         R16
    OUT         SREG, R16
    POP         R16
    RETI

; Rutina de interrupción para Timer0 Overflow
TIMER0_OVF_ISR:
    ; Guardar el estado de los registros

    PUSH        R16
    IN          R16, SREG
    PUSH        R16
	


  ; Restaurar el estado de los registros

    POP         R16
    OUT         SREG, R16
    POP         R16
    RETI
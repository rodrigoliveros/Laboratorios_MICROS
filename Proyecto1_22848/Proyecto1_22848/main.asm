;
; Proyecto1_22848.asm
;
; Created: 10/03/2025 10:52:25
; Author : rodri

; Definiciones de registros y constantes
.include "M328PDEF.inc"  ; Incluir definiciones para el ATmega328P

.equ	T0VALUE		=	100
.equ	MODOS		=	8
.equ	MAX_UMIN	=	10
.equ	MAX_DMIN	=	6
.equ	MAX_UHOR	=	10
.equ	MAX_DHOR	=	3
.def	MODO		=	R20
.def	MOSTRAR		=	R21
; Definición de variables en RAM
.dseg
.org	SRAM_START //0x0100
SFLAG:	.byte	1
USEG:	.byte	1
DSEG:   .byte	1
UMIN:	.byte	1
DMIN:	.byte	1
UHOR:	.byte	1
DHOR:	.byte	1
UMES:	.byte	1
DMES:	.byte	1
UDIAS:	.byte	1
DDIAS: .byte	1
; Variables para modificar
M_MIN: .byte	1
M_UMIN: .byte	1
M_DMIN: .byte	1
M_HOR:	.byte	1
M_UHOR:	.byte	1
M_DHOR: .byte	1
M_DIAS: .byte	1
M_UDIAS: .byte	1
M_DDIAS: .byte	1
M_MESES: .byte	1
M_UMESES: .byte 1
M_DMESES: .byte 1
CONTROL:.byte	1
CONTROL1:.byte	1
CONTROL2:.byte	1
CONTROL3:.byte	1
CONTROL4:.byte	1
CONTROL5:.byte	1
AFLAG:	.byte	1
DFLAG:  .byte	1
A_UMIN: .byte	1
A_DMIN: .byte	1
A_UHOR: .byte	1
A_DHOR:	.byte	1	
AM_MIN:	.byte	1
AM_HOR: .byte	1
AM_UMIN: .byte	1
AM_DMIN: .byte	1
AM_UHOR: .byte	1
AM_DHOR: .byte	1

; Vectores de interrupción
.cseg
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

    ; Configurar Timer0  (10 ms)
	//LDI         R16, (1 << CS00) ; Prescaler de 1
	LDI         R16, (1 << CS02) | (1 << CS00) ; Prescaler de 1024
    OUT         TCCR0B, R16
    LDI         R16, (1 << TOIE0)              ; Habilitar interrupción por overflow
    STS         TIMSK0, R16
	LDI			R16, T0VALUE
	OUT			TCNT0, R16
	
	; Tabla de conversión para display de 7 segmentos (cátodo común)
	TABLA7SEGM: .db 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F

	; Inicializar variables

	; Registros R0 -R31
	CLR			MODO
	CLR			MOSTRAR

	; Registros RAM
	LDI			R16, 0x00
	STS			UMIN, R16
	STS			DMIN, R16
	STS			UHOR, R16
	STS			DHOR, R16
	STS			USEG, R16
	STS			DSEG, R16
	STS			SFLAG, R16
	STS			UMES, R16
	STS			DMES, R16
	STS			UDIAS, R16
	STS			DDIAS, R16
	STS			M_MIN, R16
	STS			M_HOR, R16
	STS			M_UMIN, R16
	STS			M_DMIN, R16
	STS			M_UHOR, R16
	STS			M_DHOR, R16
	STS			M_MESES, R16
	STS			M_UMESES, R16
	STS			M_DMESES, R16
	STS			M_DIAS, R16
	STS			M_UDIAS, R16
	STS			M_DDIAS, R16
	STS			CONTROL, R16
	STS			CONTROL1, R16
	STS			CONTROL2, R16
	STS			CONTROL3, R16
	STS			CONTROL4, R16
	STS			CONTROL5, R16
	STS			AFLAG, R16
	STS			DFLAG, R16	
	STS			A_UMIN, R16
	STS			A_DMIN, R16
	STS			A_UHOR, R16
	STS			A_DHOR, R16	
	STS			AM_MIN, R16
	STS			AM_HOR, R16
	STS			AM_UMIN, R16
	STS			AM_DMIN, R16
	STS			AM_UHOR, R16
	STS			AM_DHOR, R16

    ; Habilitar interrupciones globales
    SEI

;MAIN
MAIN_LOOP:
	
	OUT		PORTD, MOSTRAR	
	CPI		MODO, 0
	BRNE	SIGUIENTE1
	JMP		S_HORA  
	SIGUIENTE1:
	CPI		MODO, 1
	BRNE	SIGUIENTE2
	JMP		S_FECHA
	SIGUIENTE2:
	CPI		MODO, 2
	BRNE	SIGUIENTE3
	JMP		M_HORA_MIN
	SIGUIENTE3:
	CPI		MODO, 3
	BRNE	SIGUIENTE4
	JMP		M_HORA_HOR
	SIGUIENTE4:
	CPI		MODO, 4
	BRNE	SIGUIENTE5
	JMP		M_FECHA_MES
	SIGUIENTE5:
	CPI		MODO, 5
	BRNE	SIGUIENTE6
	JMP		M_FECHA_DIA
	SIGUIENTE6:
	CPI		MODO, 6
	BRNE	SIGUIENTE7
	JMP		M_ALARM_MIN
	SIGUIENTE7:
	CPI		MODO, 7
	BRNE	FIN
	JMP		M_ALARM_HORA
	FIN:


;Subrutinas de estado
S_HORA:							; LEDS |-|0|
	SBI			PORTC, PC5 
	CBI			PORTC, PC4
	; Menu de intercambio para displays
	LDS			R16, SFLAG
	CPI			R16, 0
	BREQ		COM1
	CPI			R16, 1
	BREQ		COM2
	CPI			R16, 2
	BREQ		COM3
	CPI			R16, 3
	BREQ		COM4

	COM1:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, UMIN
		ADD         ZL, R16								; Añadir el valor de UMIN a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB0
		RJMP		MAIN_LOOP
	COM2:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, DMIN
		ADD         ZL, R16								; Añadir el valor de DMIN a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB1
		RJMP		MAIN_LOOP
	COM3:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, UHOR
		ADD         ZL, R16								; Añadir el valor de UHOR a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB2
		RJMP		MAIN_LOOP
	COM4:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, DHOR
		ADD         ZL, R16								; Añadir el valor de DHOR a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB3
		RJMP		MAIN_LOOP
S_FECHA:						; LEDS |0|-|
	CBI			PORTC, PC5
	SBI			PORTC, PC4
	; Menu de intercambio para displays
	LDS			R16, SFLAG
	CPI			R16, 0
	BREQ		M_COM1
	CPI			R16, 1
	BREQ		M_COM2
	CPI			R16, 2
	BREQ		M_COM3
	CPI			R16, 3
	BREQ		M_COM4

	M_COM1:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, UMES
		ADD         ZL, R16								; Añadir el valor de M_UMIN a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB0
		RJMP		MAIN_LOOP
	M_COM2:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, DMES
		ADD         ZL, R16								; Añadir el valor de M_DMIN a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB1
		RJMP		MAIN_LOOP
	M_COM3:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, UDIAS
		ADD         ZL, R16								; Añadir el valor de M_UHOR a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB2
		RJMP		MAIN_LOOP
	M_COM4:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, DDIAS
		ADD         ZL, R16								; Añadir el valor de M_DHOR a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB3
		RJMP		MAIN_LOOP
M_HORA_MIN:						; LEDS |-|0|		
	SBI			PORTC, PC5
	CBI			PORTC, PC4
	; Menu de intercambio para displays
	LDS			R16, SFLAG
	CPI			R16, 0
	BREQ		M0_COM1
	CPI			R16, 1
	BREQ		M0_COM2
	CPI			R16, 2
	BREQ		M0_COM3
	CPI			R16, 3
	BREQ		M0_COM4

	M0_COM1:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, M_UMIN
		ADD         ZL, R16								; Añadir el valor de M_UMIN a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB0
		RJMP		MAIN_LOOP
	M0_COM2:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, M_DMIN
		ADD         ZL, R16								; Añadir el valor de M_DMIN a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB1
		RJMP		MAIN_LOOP
	M0_COM3:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, M_UHOR
		ADD         ZL, R16								; Añadir el valor de M_UHOR a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB2
		RJMP		MAIN_LOOP
	M0_COM4:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, M_DHOR
		ADD         ZL, R16								; Añadir el valor de M_DHOR a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB3
		RJMP		MAIN_LOOP
M_HORA_HOR:						; LEDS |-|0|
	SBI			PORTC, PC5
	CBI			PORTC, PC4
	; Menu de intercambio para displays
	LDS			R16, SFLAG
	CPI			R16, 0
	BREQ		M1_COM1
	CPI			R16, 1
	BREQ		M1_COM2
	CPI			R16, 2
	BREQ		M1_COM3
	CPI			R16, 3
	BREQ		M1_COM4

	M1_COM1:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, M_UMIN
		ADD         ZL, R16								; Añadir el valor de M_UMIN a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB0
		RJMP		MAIN_LOOP
	M1_COM2:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, M_DMIN
		ADD         ZL, R16								; Añadir el valor de M_DMIN a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB1
		RJMP		MAIN_LOOP
	M1_COM3:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, M_UHOR
		ADD         ZL, R16								; Añadir el valor de M_UHOR a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB2
		RJMP		MAIN_LOOP
	M1_COM4:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, M_DHOR
		ADD         ZL, R16								; Añadir el valor de M_DHOR a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB3
		RJMP		MAIN_LOOP
M_FECHA_MES:					; LEDS |0|-|
	CBI			PORTC, PC5
	SBI			PORTC, PC4
	; Menu de intercambio para displays
	LDS			R16, SFLAG
	CPI			R16, 0
	BREQ		M2_COM1
	CPI			R16, 1
	BREQ		M2_COM2
	CPI			R16, 2
	BREQ		M2_COM3
	CPI			R16, 3
	BREQ		M2_COM4

	M2_COM1:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, M_UMESES
		ADD         ZL, R16								; Añadir el valor de M_UMIN a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB0
		RJMP		MAIN_LOOP
	M2_COM2:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, M_DMESES
		ADD         ZL, R16								; Añadir el valor de M_DMIN a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB1
		RJMP		MAIN_LOOP
	M2_COM3:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, M_UDIAS
		ADD         ZL, R16								; Añadir el valor de M_UHOR a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB2
		RJMP		MAIN_LOOP
	M2_COM4:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, M_DDIAS
		ADD         ZL, R16								; Añadir el valor de M_DHOR a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB3
		RJMP		MAIN_LOOP
M_FECHA_DIA:					; LEDS |0|-|
	CBI			PORTC, PC5
	SBI			PORTC, PC4
	; Menu de intercambio para displays
	LDS			R16, SFLAG
	CPI			R16, 0
	BREQ		M3_COM1
	CPI			R16, 1
	BREQ		M3_COM2
	CPI			R16, 2
	BREQ		M3_COM3
	CPI			R16, 3
	BREQ		M3_COM4

	M3_COM1:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, M_UMESES
		ADD         ZL, R16								; Añadir el valor de M_UMIN a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB0
		RJMP		MAIN_LOOP
	M3_COM2:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, M_DMESES
		ADD         ZL, R16								; Añadir el valor de M_DMIN a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB1
		RJMP		MAIN_LOOP
	M3_COM3:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, M_UDIAS
		ADD         ZL, R16								; Añadir el valor de M_UHOR a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB2
		RJMP		MAIN_LOOP
	M3_COM4:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, M_DDIAS
		ADD         ZL, R16								; Añadir el valor de M_DHOR a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB3
		RJMP		MAIN_LOOP
M_ALARM_MIN:					; LEDS |0|0|
	SBI			PORTC, PC5
	SBI			PORTC, PC4
	; Menu de intercambio para displays
	LDS			R16, SFLAG
	CPI			R16, 0
	BREQ		M4_COM1
	CPI			R16, 1
	BREQ		M4_COM2
	CPI			R16, 2
	BREQ		M4_COM3
	CPI			R16, 3
	BREQ		M4_COM4

	M4_COM1:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, A_UMIN
		ADD         ZL, R16								; Añadir el valor de UMIN a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB0
		RJMP		MAIN_LOOP
	M4_COM2:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, A_DMIN
		ADD         ZL, R16								; Añadir el valor de DMIN a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB1
		RJMP		MAIN_LOOP
	M4_COM3:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, A_UHOR
		ADD         ZL, R16								; Añadir el valor de UHOR a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB2
		RJMP		MAIN_LOOP
	M4_COM4:
		CBI			PORTB, PB0
		CBI			PORTB, PB1
		CBI			PORTB, PB2
		CBI			PORTB, PB3	
		; Cargar la dirección de UMIN a  la tabla de 7 segmentos
		LDI         ZH, HIGH(TABLA7SEGM << 1)			; Parte alta de la dirección de la tabla
		LDI         ZL, LOW(TABLA7SEGM << 1)			; Parte baja de la dirección de la tabla
		LDS			R16, A_DHOR
		ADD         ZL, R16								; Añadir el valor de DHOR a ZL
		LPM         MOSTRAR, Z							; Leer el valor de la tabla de 7 segmentos
		; Mostrar el valor en el display de 7 segmentos (PORTD)
		SBI			PORTB, PB3
		RJMP		MAIN_LOOP
M_ALARM_HORA:					; LEDS |0|0|
	LDI			MOSTRAR, 0x07
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
	SBIS        PINC, PC0    ; Verifico si el pin modo está presionado "0"
	INC         MODO        
	LDI         R16, MODOS   ; MODOS es el valor máximo de modos
	CP          MODO, R16
	BRLO        CHECK_MODE   ; Si MODO < MODOS, seguimos
	CLR         MODO         ; Si MODO >= MODOS, lo reiniciamos

CHECK_MODE:
    CPI         MODO, 0
    BREQ        JMP_MODO0
    CPI         MODO, 1
    BREQ        JMP_MODO1
    CPI         MODO, 2
    BREQ        JMP_MODO2
    CPI         MODO, 3
    BREQ        JMP_MODO3
    CPI         MODO, 4
    BREQ        JMP_MODO4
    CPI         MODO, 5
    BREQ        JMP_MODO5
    CPI         MODO, 6
    BREQ        JMP_MODO6
    CPI         MODO, 7
    BREQ        JMP_MODO7
    RJMP        EXIT_PDINT1_ISR

	JMP_MODO0:    JMP MODO0_ISR
	JMP_MODO1:    JMP MODO1_ISR
	JMP_MODO2:    JMP MODO2_ISR
	JMP_MODO3:    JMP MODO3_ISR
	JMP_MODO4:    JMP MODO4_ISR
	JMP_MODO5:    JMP MODO5_ISR
	JMP_MODO6:    JMP MODO6_ISR
	JMP_MODO7:    JMP MODO7_ISR

MODO0_ISR:
    ; Relacionado con mostrar hora
    RJMP EXIT_PDINT1_ISR
MODO1_ISR:
    ; Relacionado con mostrar fecha
    RJMP EXIT_PDINT1_ISR
MODO2_ISR:
    ; Relacionado con configurar minutos
    ; Manejo de banderas para Aumentar o Decrementar
    LDS         R16, AFLAG				; Cargamos el valor de AFLAG en caso este presionado aumentar
    SBIS        PINC, PC1  
    LDI         R16, 1					; Si esta presionado activamos bandera
    STS         AFLAG, R16				; Guardamos el valor de la bandera
    LDS         R16, DFLAG				; Cargamos el valor de DFLAG en caso este presionado 
    SBIS        PINC, PC2  
    LDI         R16, 1					; Si esta presionado activamos bandera
    STS         DFLAG, R16				; Guardamos el valor de la bandera
    ; Direccionamiento a rutinas
    LDS         R16, AFLAG				
    CPI         R16, 1					; Verificamos si se presiono AUMENTAR
    BREQ        AUMENTAR				; Si se presiono vamos a la subrutina
    LDS         R16, DFLAG		
    CPI         R16, 1					; Verificamos si se presiono  DECREMENTAR
    BREQ        DECREMENTAR				; Si se presiono vamos a la subrutina
    RJMP        EXIT_PDINT1_ISR
	AUMENTAR:
    CLR         R16
    STS         AFLAG, R16				; Borramos la bandera y guardamos el valor
    LDS         R16, M_MIN				; Cargamos la variable de modificar minutos
    INC         R16						; La incrementamos
    CPI         R16, 60					; Comparamos si llego a 60 (límite)
    BRLO        STORE_M_MIN				; Si no ha llegado la procedemos a guardar
    LDI			R16, 0x00			    ; Si llego al limite borramos  y guardamos
	STS			M_MIN, R16
    RJMP        STORE_M_MIN	
	DECREMENTAR:
    CLR         R16						
    STS         DFLAG, R16               ; Borramos la bandera y guardamos el valor
    LDS         R16, M_MIN               ; Cargamos la variable de modificar minutos
    DEC         R16                      ; Decrementamos el valor 
    
    CPI         R16, 60                  ; ¿Es menor que 60?
    BRLO        STORE_M_MIN              ; Si es menor, es válido (0-59), guardamos y salimos
    LDI         R16, 59                  ; Si el valor es 255, 254, ..., lo corregimos a 59
	STORE_M_MIN:
    STS         M_MIN, R16               ; Guardamos el valor corregido
    LDS         R16, M_MIN
    STS         CONTROL, R16             ; Guardamos en CONTROL nuestra variable editable
	PARTIR:
    ; Reiniciamos M_DMIN antes de comenzar a calcular
    CLR         R17
    STS         M_DMIN, R17

    LDS         R16, CONTROL            ; Cargamos el valor de CONTROL (0-59)
    
	CONVERTIR_DECENAS:
    CPI         R16, 10                  ; ¿Es menor a 10?
    BRLO        GUARDAR_UNIDADES         ; Si sí, ya tenemos las unidades, salimos
    
    SUBI        R16, 10                   ; Restamos 10
    INC         R17                       ; Incrementamos M_DMIN (decenas)
    RJMP        CONVERTIR_DECENAS         ; Repetimos hasta que R16 < 10
    
	GUARDAR_UNIDADES:
    STS         M_UMIN, R16               ; Guardamos unidades
    STS         UMIN, R16                 ; Actualizamos la pantalla
    STS         M_DMIN, R17               ; Guardamos decenas
    STS         DMIN, R17                 ; Actualizamos la pantalla

    RJMP        EXIT_PDINT1_ISR


MODO3_ISR:
    ; Relacionado con configurar hora    
	; Manejo de banderas para Aumentar o Decrementar
    LDS         R16, AFLAG				; Cargamos el valor de AFLAG en caso este presionado aumentar
    SBIS        PINC, PC1  
    LDI         R16, 1					; Si esta presionado activamos bandera
    STS         AFLAG, R16				; Guardamos el valor de la bandera
    LDS         R16, DFLAG				; Cargamos el valor de DFLAG en caso este presionado 
    SBIS        PINC, PC2  
    LDI         R16, 1					; Si esta presionado activamos bandera
    STS         DFLAG, R16				; Guardamos el valor de la bandera
    ; Direccionamiento a rutinas
    LDS         R16, AFLAG				
    CPI         R16, 1					; Verificamos si se presiono AUMENTAR
    BREQ        AUMENTAR1				; Si se presiono vamos a la subrutina
    LDS         R16, DFLAG		
    CPI         R16, 1					; Verificamos si se presiono  DECREMENTAR
    BREQ        DECREMENTAR1			; Si se presiono vamos a la subrutina
    RJMP        EXIT_PDINT1_ISR
	AUMENTAR1:
    CLR         R16
    STS         AFLAG, R16				; Borramos la bandera y guardamos el valor
    LDS         R16, M_HOR				; Cargamos la variable de modificar minutos
    INC         R16						; La incrementamos
    CPI         R16, 24					; Comparamos si llego a 24 (límite)
    BRLO        STORE_M_HOR				; Si no ha llegado la procedemos a guardar
    LDI			R16, 0x00			    ; Si llego al limite borramos  y guardamos
	STS			M_HOR, R16
    RJMP        STORE_M_HOR	
	DECREMENTAR1:
    CLR         R16						
    STS         DFLAG, R16               ; Borramos la bandera y guardamos el valor
    LDS         R16, M_HOR               ; Cargamos la variable de modificar minutos
    DEC         R16                      ; Decrementamos el valor 
    
    CPI         R16, 24                  ; ¿Es menor que 24?
    BRLO        STORE_M_HOR              ; Si es menor, es válido (0-59), guardamos y salimos
    LDI         R16, 23                  ; Si el valor es 255, 254, ..., lo corregimos a 23
	STORE_M_HOR:
    STS         M_HOR, R16               ; Guardamos el valor corregido
    LDS         R16, M_HOR
    STS         CONTROL1, R16             ; Guardamos en CONTROL nuestra variable editable
	PARTIR1:
    ; Reiniciamos M_DMIN antes de comenzar a calcular
    CLR         R17
    STS         M_DHOR, R17

    LDS         R16, CONTROL1            ; Cargamos el valor de CONTROL (0-24)
    
	CONVERTIR_DECENAS1:
    CPI         R16, 10                  ; ¿Es menor a 10?
    BRLO        GUARDAR_UNIDADES1         ; Si sí, ya tenemos las unidades, salimos
    
    SUBI        R16, 10                   ; Restamos 10
    INC         R17                       ; Incrementamos M_DMIN (decenas)
    RJMP        CONVERTIR_DECENAS1         ; Repetimos hasta que R16 < 10
    
	GUARDAR_UNIDADES1:
    STS         M_UHOR, R16               ; Guardamos unidades
    STS         UHOR, R16                 ; Actualizamos la pantalla
    STS         M_DHOR, R17               ; Guardamos decenas
    STS         DHOR, R17                 ; Actualizamos la pantalla

    RJMP        EXIT_PDINT1_ISR

MODO4_ISR:
    ; Relacionado con configurar meses
    ; Manejo de banderas para Aumentar o Decrementar
    LDS         R16, AFLAG				; Cargamos el valor de AFLAG en caso este presionado aumentar
    SBIS        PINC, PC1  
    LDI         R16, 1					; Si esta presionado activamos bandera
    STS         AFLAG, R16				; Guardamos el valor de la bandera
    LDS         R16, DFLAG				; Cargamos el valor de DFLAG en caso este presionado 
    SBIS        PINC, PC2  
    LDI         R16, 1					; Si esta presionado activamos bandera
    STS         DFLAG, R16				; Guardamos el valor de la bandera
    ; Direccionamiento a rutinas
    LDS         R16, AFLAG				
    CPI         R16, 1					; Verificamos si se presiono AUMENTAR
    BREQ        AUMENTAR2				; Si se presiono vamos a la subrutina
    LDS         R16, DFLAG		
    CPI         R16, 1					; Verificamos si se presiono  DECREMENTAR
    BREQ        DECREMENTAR2				; Si se presiono vamos a la subrutina
    RJMP        EXIT_PDINT1_ISR
	AUMENTAR2:
    CLR         R16
    STS         AFLAG, R16				; Borramos la bandera y guardamos el valor
    LDS         R16, M_MESES			; Cargamos la variable de modificar meses
    INC         R16						; La incrementamos
    CPI         R16, 13					; Comparamos si llego a 13 (límite)
    BRLO        STORE_M_MESES			; Si no ha llegado la procedemos a guardar
    LDI			R16, 1				    ; Si llego al limite borramos  y guardamos
	STS			M_MESES, R16
    RJMP        STORE_M_MESES
	DECREMENTAR2:
    CLR         R16						
    STS         DFLAG, R16               ; Borramos la bandera y guardamos el valor
    LDS         R16, M_MESES             ; Cargamos la variable de modificar meses
    DEC         R16                      ; Decrementamos el valor 
    
    CPI         R16, 0                  ; ¿Es menor que 1?
    BRNE        STORE_M_MESES              ; Si es menor, es válido (0-12), guardamos y salimos
    LDI         R16, 12                  ; Si el valor es 255, 254, ..., lo corregimos a 12
	STORE_M_MESES:
    STS         M_MESES, R16               ; Guardamos el valor corregido
    LDS         R16, M_MESES
    STS         CONTROL2, R16             ; Guardamos en CONTROL nuestra variable editable
	PARTIR2:
    ; Reiniciamos M_DMESES antes de comenzar a calcular
    CLR         R17
    STS         M_DMESES, R17

    LDS         R16, CONTROL2            ; Cargamos el valor de CONTROL (0-12)
    
	CONVERTIR_DECENAS2:
    CPI         R16, 10                  ; ¿Es menor a 10?
    BRLO        GUARDAR_UNIDADES2        ; Si sí, ya tenemos las unidades, salimos
    
    SUBI        R16, 10                   ; Restamos 10
    INC         R17                       ; Incrementamos M_DMIN (decenas)
    RJMP        CONVERTIR_DECENAS2         ; Repetimos hasta que R16 < 10
    
	GUARDAR_UNIDADES2:
    STS         M_UMESES, R16               ; Guardamos unidades
    STS         UMES, R16                 ; Actualizamos la pantalla
    STS         M_DMESES, R17               ; Guardamos decenas
    STS         DMES, R17                 ; Actualizamos la pantalla

    RJMP        EXIT_PDINT1_ISR
MODO5_ISR:
    ; Relacionado con configurar días
    ; Manejo de banderas para Aumentar o Decrementar
    LDS         R16, AFLAG				; Cargamos el valor de AFLAG en caso este presionado aumentar
    SBIS        PINC, PC1  
    LDI         R16, 1					; Si esta presionado activamos bandera
    STS         AFLAG, R16				; Guardamos el valor de la bandera
    LDS         R16, DFLAG				; Cargamos el valor de DFLAG en caso este presionado 
    SBIS        PINC, PC2  
    LDI         R16, 1					; Si esta presionado activamos bandera
    STS         DFLAG, R16				; Guardamos el valor de la bandera
    ; Direccionamiento a rutinas
    LDS         R16, AFLAG				
    CPI         R16, 1					; Verificamos si se presiono AUMENTAR
    BREQ        AUMENTAR3				; Si se presiono vamos a la subrutina
    LDS         R16, DFLAG		
    CPI         R16, 1					; Verificamos si se presiono  DECREMENTAR
    BREQ        DECREMENTAR3			; Si se presiono vamos a la subrutina
    RJMP        EXIT_PDINT1_ISR
	AUMENTAR3:
    CLR         R16
    STS         AFLAG, R16				; Borramos la bandera y guardamos el valor
    LDS         R16, M_DIAS				; Cargamos la variable de modificar meses
    INC         R16						; La incrementamos
    CPI         R16, 32					; Comparamos si llego a 32 (límite)
    BRLO        STORE_M_DIAS			; Si no ha llegado la procedemos a guardar
    LDI			R16, 1				    ; Si llego al limite borramos  y guardamos
	STS			M_DIAS, R16
    RJMP        STORE_M_DIAS
	DECREMENTAR3:
    CLR         R16						
    STS         DFLAG, R16               ; Borramos la bandera y guardamos el valor
    LDS         R16, M_DIAS             ; Cargamos la variable de modificar meses
    DEC         R16                      ; Decrementamos el valor 
    
    CPI         R16, 0                  ; ¿Es menor que 1?
    BRNE        STORE_M_DIAS              ; Si es menor, es válido (0-31), guardamos y salimos
    LDI         R16, 31                  ; Si el valor es 255, 254, ..., lo corregimos a 12
	STORE_M_DIAS:
    STS         M_DIAS, R16               ; Guardamos el valor corregido
    LDS         R16, M_DIAS
    STS         CONTROL3, R16             ; Guardamos en CONTROL nuestra variable editable
	PARTIR3:
    ; Reiniciamos M_DDIAS antes de comenzar a calcular
    CLR         R17
    STS         M_DDIAS, R17

    LDS         R16, CONTROL3            ; Cargamos el valor de CONTROL (0-31)
    
	CONVERTIR_DECENAS3:
    CPI         R16, 10                  ; ¿Es menor a 10?
    BRLO        GUARDAR_UNIDADES3        ; Si sí, ya tenemos las unidades, salimos
    
    SUBI        R16, 10                   ; Restamos 10
    INC         R17                       ; Incrementamos M_DMIN (decenas)
    RJMP        CONVERTIR_DECENAS3         ; Repetimos hasta que R16 < 10
    
	GUARDAR_UNIDADES3:
    STS         M_UDIAS, R16               ; Guardamos unidades
    STS         UDIAS, R16                 ; Actualizamos la pantalla
    STS         M_DDIAS, R17               ; Guardamos decenas
    STS         DDIAS, R17                 ; Actualizamos la pantalla

    RJMP        EXIT_PDINT1_ISR
MODO6_ISR:
    ; Relacionado con alarma minutos
    ; Manejo de banderas para Aumentar o Decrementar
    LDS         R16, AFLAG				; Cargamos el valor de AFLAG en caso este presionado aumentar
    SBIS        PINC, PC1  
    LDI         R16, 1					; Si esta presionado activamos bandera
    STS         AFLAG, R16				; Guardamos el valor de la bandera
    LDS         R16, DFLAG				; Cargamos el valor de DFLAG en caso este presionado 
    SBIS        PINC, PC2  
    LDI         R16, 1					; Si esta presionado activamos bandera
    STS         DFLAG, R16				; Guardamos el valor de la bandera
    ; Direccionamiento a rutinas
    LDS         R16, AFLAG				
    CPI         R16, 1					; Verificamos si se presiono AUMENTAR
    BREQ        AUMENTAR4				; Si se presiono vamos a la subrutina
    LDS         R16, DFLAG		
    CPI         R16, 1					; Verificamos si se presiono  DECREMENTAR
    BREQ        DECREMENTAR4				; Si se presiono vamos a la subrutina
    RJMP        EXIT_PDINT1_ISR
	AUMENTAR4:
    CLR         R16
    STS         AFLAG, R16				; Borramos la bandera y guardamos el valor
    LDS         R16, AM_MIN				; Cargamos la variable de modificar minutos
    INC         R16						; La incrementamos
    CPI         R16, 60					; Comparamos si llego a 60 (límite)
    BRLO        STORE_AM_MIN			; Si no ha llegado la procedemos a guardar
    LDI			R16, 0x00			    ; Si llego al limite borramos  y guardamos
	STS			AM_MIN, R16
    RJMP        STORE_AM_MIN	
	DECREMENTAR4:
    CLR         R16						
    STS         DFLAG, R16               ; Borramos la bandera y guardamos el valor
    LDS         R16, AM_MIN               ; Cargamos la variable de modificar minutos
    DEC         R16                      ; Decrementamos el valor 
    
    CPI         R16, 60                  ; ¿Es menor que 60?
    BRLO        STORE_AM_MIN              ; Si es menor, es válido (0-59), guardamos y salimos
    LDI         R16, 59                  ; Si el valor es 255, 254, ..., lo corregimos a 59
	STORE_AM_MIN:
    STS         AM_MIN, R16               ; Guardamos el valor corregido
    LDS         R16, AM_MIN
    STS         CONTROL4, R16             ; Guardamos en CONTROL nuestra variable editable
	PARTIR4:
    ; Reiniciamos AM_DMIN antes de comenzar a calcular
    CLR         R17
    STS         AM_DMIN, R17

    LDS         R16, CONTROL4            ; Cargamos el valor de CONTROL (0-59)
    
	CONVERTIR_DECENAS4:
    CPI         R16, 10                  ; ¿Es menor a 10?
    BRLO        GUARDAR_UNIDADES4         ; Si sí, ya tenemos las unidades, salimos
    
    SUBI        R16, 10                   ; Restamos 10
    INC         R17                       ; Incrementamos M_DMIN (decenas)
    RJMP        CONVERTIR_DECENAS4         ; Repetimos hasta que R16 < 10
    
	GUARDAR_UNIDADES4:
    STS         AM_UMIN, R16               ; Guardamos unidades
    STS         A_UMIN, R16                 ; Actualizamos la pantalla
    STS         AM_DMIN, R17               ; Guardamos decenas
    STS         A_DMIN, R17                 ; Actualizamos la pantalla

    RJMP        EXIT_PDINT1_ISR

MODO7_ISR:
    ; Relacionado con alarma horas
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
	
	; Reiniciar TIMER0
	LDI			R16, T0VALUE
	OUT			TCNT0, R16
	
	; Lógica de Hora
	LDS			R16, SFLAG			; Aquí alternamos la bandera SFLAG que nos servira para alternar entre los displays
	INC			R16
	CPI			R16, 4
	BRNE		RELOJ
	CLR			R16
	STS			SFLAG, R16
RELOJ:
	STS			SFLAG, R16
	LDS			R16, USEG
	INC			R16
	CPI			R16, 100			; Aquí verificamos si ya pasaron 1000 ms
	BRNE		STORE_USEG
	CLR			R16
	STS			USEG, R16			; Ya paso 1 seg, borramos y guardamos valor
	LDS			R16, DSEG
	INC			R16
	CPI			R16, 60				; Verificamos si ya paso 60 seg
	BRNE		STORE_DSEG
	CLR			R16
	STS			DSEG, R16			; Paso 1 min, borramos y guardamos valor
	LDS			R16, UMIN
	INC			R16
	CPI			R16, MAX_UMIN		; Verificamos si pasaron 10 min
	BRNE		STORE_UMIN
	CLR			R16
	STS			UMIN, R16			; Ya pasaron 10 min, borramos y guardamos valor
	LDS			R16, DMIN
	INC			R16
	CPI			R16, MAX_DMIN		; Verificamos si pasaron 60 min
	BRNE		STORE_DMIN
	CLR			R16
	STS			DMIN, R16			; Ya pasaron 60 min, borramos y guardamos valor
	LDS			R16, DHOR
	CPI			R16, 2				; Verificamos si estamos por debajo de las 20 horas
	BRNE		HORA_NORMAL			; Si estamos por debajo, hacemos el overflow normal cada 10 horas
	LDS			R16, UHOR			; Si no estamos por debajo hacemos el overflow despues de 4 horas
	INC			R16
	CPI			R16, 4				; Verificamos si llegamos a las 24 horas
	BRNE		STORE_UHOR			; Si no hemos llegado, guardamos y seguimos contando
	CLR			R16					; Si llegamos, borramos y guardamos valor para UHORA y DHORA.
	STS			UHOR, R16
	STS			DHOR, R16
	CALL		ACT_FECHA
	HORA_NORMAL:
	LDS			R16, UHOR	
	INC			R16
	CPI			R16, MAX_UHOR		; Verificamos si pasaron 10 horas
	BRNE		STORE_UHOR
	CLR			R16
	STS			UHOR, R16			; Ya pasaron 10 horas, borramos y guardamos valor
	LDS			R16, DHOR
	INC			R16		
	STS			DHOR, R16
	RJMP		EXIT_TIMER0_ISR

	; Rutinas de guardado 
STORE_USEG:
	STS			USEG, R16
	RJMP		EXIT_TIMER0_ISR
STORE_DSEG:
	STS			DSEG, R16
	RJMP		EXIT_TIMER0_ISR
STORE_UMIN:
	STS			UMIN, R16
	RJMP		EXIT_TIMER0_ISR
STORE_DMIN:
	STS			DMIN, R16
	RJMP		EXIT_TIMER0_ISR
STORE_UHOR:
	STS			UHOR, R16
	RJMP		EXIT_TIMER0_ISR
STORE_DHOR:
	STS			DHOR, R16
	RJMP		EXIT_TIMER0_ISR
ACT_FECHA:

	; Overflow de fecha
	LDS			R16, M_DIAS
	INC			R16
	PARTIR6:
    ; Reiniciamos M_DDIAS antes de comenzar a calcular
    CLR         R17
    STS         M_DDIAS, R17
    
	CONVERTIR_DECENAS6:
    CPI         R16, 10                  ; ¿Es menor a 10?
    BRLO        GUARDAR_UNIDADES6        ; Si sí, ya tenemos las unidades, salimos
    
    SUBI        R16, 10                   ; Restamos 10
    INC         R17                       ; Incrementamos M_DMIN (decenas)
    RJMP        CONVERTIR_DECENAS6         ; Repetimos hasta que R16 < 10
    
	GUARDAR_UNIDADES6:
    STS         UDIAS, R16                 ; Actualizamos la pantalla
    STS         DDIAS, R17                 ; Actualizamos la pantalla

	RJMP		EXIT_TIMER0_ISR

EXIT_TIMER0_ISR:
	; Restaurar el estado de los registros

    POP         R16
    OUT         SREG, R16
    POP         R16
    RETI